defmodule IST.Systems.BoostShields do
  @moduledoc """
  Adds hit points to the ship's shields.
  Checks if the ship has enough energy to boost shields and consumes it.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.EnergyStorage,
      IST.Components.Shields
    ]

  alias Ecspanse.Query
  alias IST.Events.BoostShields, as: BoostEvent

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, frame) do
    entities =
      events
      |> Stream.filter(fn
        %BoostEvent{} -> true
        _ -> false
      end)
      |> Enum.map(fn %BoostEvent{ship_id: id} ->
        Ecspanse.Entity.build(id)
      end)

    if Enum.any?(entities) do
      boost_shields(entities, frame.token)
    end
  end

  defp boost_shields(entities, token) do
    Query.select({IST.Components.EnergyStorage, Ecspanse.Component.Children},
      with: [IST.Components.BattleShip],
      for: entities
    )
    |> Query.stream(token)
    |> Enum.each(fn {energy_component, children} ->
      shields_entity =
        children.list
        |> Enum.find(fn entity ->
          Ecspanse.Query.has_component?(entity, IST.Components.Shields, token)
        end)

      {:ok, {shields_component, energy_cost_component}} =
        Ecspanse.Query.fetch_components(
          shields_entity,
          {IST.Components.Shields, IST.Components.EnergyCost},
          token
        )

      # Example of using individual component update instead of batch updating
      if energy_component.value >= energy_cost_component.value do
        :ok =
          Ecspanse.Command.update_component!(energy_component,
            value: energy_component.value - energy_cost_component.value
          )

        :ok =
          Ecspanse.Command.update_component!(shields_component,
            hp: shields_component.hp + shields_component.boost
          )
      end
    end)
  end
end
