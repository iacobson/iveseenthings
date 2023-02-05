defmodule IST.Systems.AddEnergy do
  @moduledoc """
  When the counter reaches zero, add energy to the ship and resets back the counter.
  """

  use Ecspanse.System, lock_components: [IST.Components.CountDown, IST.Components.EnergyStorage]
  alias Ecspanse.Query

  alias Ecspanse.Event.ComponentUpdated

  @impl true
  def run(frame) do
    entities =
      frame.event_stream
      |> Stream.filter(fn
        %ComponentUpdated{
          final: %IST.Components.CountDown{millisecond: 0}
        } ->
          true

        _ ->
          false
      end)
      |> Stream.map(& &1.final)
      |> Enum.map(fn counter ->
        Query.get_component_entity(counter, frame.token)
      end)

    if Enum.any?(entities) do
      Query.select({IST.Components.CountDown, IST.Components.EnergyStorage},
        with: [IST.Components.BattleShip],
        for: entities
      )
      |> Query.stream(frame.token)
      |> Enum.flat_map(fn {counter, energy} ->
        [{counter, %{millisecond: counter.initial}}, {energy, %{value: energy.value + 1}}]
      end)
      |> Ecspanse.Command.update_components!()
    end
  end
end
