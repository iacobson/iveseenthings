defmodule IST.Systems.AddEnergy do
  @moduledoc """
  When the counter reaches zero, add energy to the ship and resets back the counter.
  """

  use Ecspanse.System, lock_components: [IST.Components.EnergyStorage]
  alias Ecspanse.Query

  alias Ecspanse.Event.ComponentUpdated

  @impl true
  def run(frame) do
    countdown_entities =
      frame.event_stream
      |> Stream.filter(fn
        %ComponentUpdated{
          final: %IST.Components.Countdown{millisecond: 0}
        } ->
          true

        _ ->
          false
      end)
      |> Stream.map(& &1.final)
      |> Enum.map(fn counter ->
        Query.get_component_entity(counter, frame.token)
      end)

    # Careful with this situation!
    # if a list of entities would be empty, it would query for all entities!
    if Enum.any?(countdown_entities) do
      parent_entities =
        Query.select(
          {Ecspanse.Component.Parents},
          with: [IST.Components.EnergyCountdown],
          for: countdown_entities
        )
        |> Query.stream(frame.token)
        |> Stream.map(fn {parent} -> parent.list end)
        |> Enum.concat()

      if Enum.any?(parent_entities) do
        Query.select({IST.Components.EnergyStorage},
          with: [IST.Components.BattleShip],
          for: parent_entities
        )
        |> Query.stream(frame.token)
        |> Enum.map(fn {energy} ->
          {energy, %{value: energy.value + 1}}
        end)
        |> Ecspanse.Command.update_components!()
      end
    end
  end
end
