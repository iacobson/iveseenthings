defmodule IST.Systems.EvasiveManeuvers do
  @moduledoc """
  Performs an evasive maneuvers.
  Checks if the ship has enough energy to perform the maneuver and consumes it.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.EnergyStorage,
      IST.Components.EvasionTimer
    ]

  alias IST.Events.PerformEvasiveManeuvers
  alias Ecspanse.Query

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, frame) do
    entities =
      events
      |> Stream.filter(fn
        %PerformEvasiveManeuvers{} -> true
        _ -> false
      end)
      |> Enum.map(fn %PerformEvasiveManeuvers{ship_id: id} ->
        Ecspanse.Entity.build(id)
      end)

    if Enum.any?(entities) do
      perform_evasive_maneuvers(entities)
    end
  end

  defp perform_evasive_maneuvers(entities) do
    Query.select({IST.Components.EnergyStorage, Ecspanse.Component.Children},
      with: [IST.Components.BattleShip],
      for: entities
    )
    |> Query.stream()
    |> Stream.map(fn {energy_component, children} ->
      evastion_entity =
        children.entities
        |> Enum.find(fn entity ->
          Ecspanse.Query.has_component?(entity, IST.Components.Evasion)
        end)

      {:ok, {evasion_component, energy_cost_component, evasion_timer}} =
        Ecspanse.Query.fetch_components(
          evastion_entity,
          {IST.Components.Evasion, IST.Components.EnergyCost, IST.Components.EvasionTimer}
        )

      %{
        energy_storage_component: energy_component,
        evasion_component: evasion_component,
        energy_cost_component: energy_cost_component,
        evasion_timer: evasion_timer
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
                     evasion_component: evasion,
                     energy_cost_component: energy_cost,
                     evasion_timer: evasion_timer
                   } ->
      update_energy_storage = {energy_storage, value: energy_storage.value - energy_cost.value}

      update_timer = {evasion_timer, time: evasion_timer.time + evasion.maneuvers * 1000}

      [update_energy_storage, update_timer]
    end)
    |> List.flatten()
    |> Ecspanse.Command.update_components!()
  end
end
