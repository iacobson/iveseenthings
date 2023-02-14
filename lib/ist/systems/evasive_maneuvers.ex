defmodule IST.Systems.EvasiveManeuvers do
  @moduledoc """
  Performs an evasive maneuvers.
  Checks if the ship has enough energy to perform the maneuver and consumes it.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.EnergyStorage,
      {IST.Components.Countdown, entity_type: IST.Components.EvasionCountdown}
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
      perform_evasive_maneuvers(entities, frame.token)
    end
  end

  defp perform_evasive_maneuvers(entities, token) do
    Query.select({IST.Components.EnergyStorage, Ecspanse.Component.Children},
      with: [IST.Components.BattleShip],
      for: entities
    )
    |> Query.stream(token)
    |> Stream.map(fn {energy, children} ->
      evastion_entity =
        children.list
        |> Enum.find(fn entity ->
          Ecspanse.Query.has_component?(entity, IST.Components.Evasion, token)
        end)

      {:ok, {evasion_component, energy_cost_component}} =
        Ecspanse.Query.fetch_components(
          evastion_entity,
          {IST.Components.Evasion, IST.Components.EnergyCost},
          token
        )

      %{
        energy_storage_component: energy,
        evasion_component: evasion_component,
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
                     evasion_component: evasion,
                     energy_cost_component: energy_cost
                   } ->
      evasion_entity = Query.get_component_entity(evasion, token)

      evasion_countdown_entity =
        Query.list_children(evasion_entity, token)
        |> Enum.find(fn entity ->
          Query.is_type?(entity, IST.Components.EvasionCountdown, token)
        end)

      {:ok, countdown} =
        Query.fetch_component(evasion_countdown_entity, IST.Components.Countdown, token)

      update_energy_storage = {energy_storage, value: energy_storage.value - energy_cost.value}

      update_countdown =
        {countdown, millisecond: countdown.millisecond + evasion.maneuvers * 1000}

      [update_energy_storage, update_countdown]
    end)
    |> List.flatten()
    |> Ecspanse.Command.update_components!()
  end
end
