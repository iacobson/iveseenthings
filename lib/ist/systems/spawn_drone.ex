defmodule IST.Systems.SpawnDrone do
  @moduledoc """
  Spawns a new drone.
  Checks if the ship has enough energy to spawn a drone and consumes it.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.EnergyStorage,
      IST.Components.Drones
    ]

  alias Ecspanse.Query
  alias IST.Events.SpawnDrone, as: DroneEvent

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, _frame) do
    entities =
      events
      |> Stream.filter(fn
        %DroneEvent{} -> true
        _ -> false
      end)
      |> Stream.map(fn %DroneEvent{ship_id: id} ->
        case Ecspanse.Entity.fetch(id) do
          {:ok, entity} -> entity
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if Enum.any?(entities) do
      spawn_drone(entities)
    end
  end

  defp spawn_drone(entities) do
    Query.select({IST.Components.EnergyStorage, Ecspanse.Component.Children},
      with: [IST.Components.BattleShip],
      for: entities
    )
    |> Query.stream()
    |> Stream.map(fn {energy, children} ->
      drones_entity =
        children.entities
        |> Enum.find(fn entity ->
          Ecspanse.Query.has_component?(entity, IST.Components.Drones)
        end)

      {:ok, {drones_component, energy_cost_component}} =
        Ecspanse.Query.fetch_components(
          drones_entity,
          {IST.Components.Drones, IST.Components.EnergyCost}
        )

      %{
        energy_storage_component: energy,
        drones_component: drones_component,
        energy_cost_component: energy_cost_component
      }
    end)
    |> Stream.filter(fn %{
                          energy_storage_component: energy_storage,
                          energy_cost_component: energy_cost
                        } ->
      energy_storage.value >= energy_cost.value
    end)
    |> Enum.map(fn %{
                     energy_storage_component: energy_storage,
                     drones_component: drones,
                     energy_cost_component: energy_cost
                   } ->
      update_energy_storage = {energy_storage, value: energy_storage.value - energy_cost.value}

      update_drones = {drones, count: drones.count + drones.deploy}

      [update_energy_storage, update_drones]
    end)
    |> List.flatten()
    |> Ecspanse.Command.update_components!()
  end
end
