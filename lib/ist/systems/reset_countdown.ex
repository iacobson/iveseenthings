defmodule IST.Systems.ResetCountdown do
  @moduledoc """
  When it reaches ZERO, resets the counter to the initial value.
  """

  use Ecspanse.System, lock_components: [IST.Components.Countdown]

  alias Ecspanse.Event.ComponentUpdated

  @impl true
  def run(frame) do
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
      {counter, millisecond: counter.initial}
    end)
    |> Ecspanse.Command.update_components!()
  end
end
