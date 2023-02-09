defmodule IST.Systems.ResetCountdown do
  @moduledoc """
  When it reaches ZERO, resets the countdown to the initial value.
  This relies on the Countown component being updated by the CountingDown system.
  It needs to be run at the beginning of the frame, otherwise it will
  impact other systems that may reset the coundown, such as: EvasiveManeuvers.
  """

  use Ecspanse.System

  alias Ecspanse.Event.ComponentUpdated
  alias Ecspanse.Query

  @impl true
  def run(frame) do
    entities =
      frame.event_stream
      |> Stream.filter(fn
        %ComponentUpdated{
          updated: %IST.Components.Countdown{millisecond: 0}
        } ->
          true

        _ ->
          false
      end)
      |> Stream.map(fn component_updated ->
        Query.get_component_entity(component_updated.updated, frame.token)
      end)

    # Make sure that the countdown was not updated meanwhile
    if Enum.any?(entities) do
      Query.select({IST.Components.Countdown}, for: entities)
      |> Query.stream(frame.token)
      |> Stream.map(fn {countdown} -> countdown end)
      |> Stream.filter(fn countdown -> countdown.millisecond == 0 and countdown.initial > 0 end)
      |> Enum.map(fn countdown ->
        {countdown, millisecond: countdown.initial}
      end)
      |> Ecspanse.Command.update_components!()
    end
  end
end
