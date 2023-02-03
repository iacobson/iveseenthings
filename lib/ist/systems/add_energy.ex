defmodule IST.Systems.AddEnergy do
  @moduledoc """
  When the counter reaches zero, add energy to the ship and resets back the counter.
  """

  use Ecspanse.System, lock_components: [IST.Components.CountDown, IST.Components.EnergyStorage]
  alias Ecspanse.Query

  alias Ecspanse.Event.ComponentUpdated

  @impl true
  def run(frame) do
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
    |> Ecspanse.System.execute_async(fn counter ->
      entity = Query.get_component_entity(counter, frame.token)

      if Query.has_component?(entity, IST.Components.BattleShip, frame.token) do
        {:ok, energy} = Query.fetch_component(entity, IST.Components.EnergyStorage, frame.token)

        Ecspanse.Command.update_component!(counter, %{millisecond: counter.initial})
        Ecspanse.Command.update_component!(energy, %{value: energy.value + 1})
      end
    end)
  end
end
