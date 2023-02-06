defmodule IST.Systems.TargetLock do
  @moduledoc """
  Acquires a target lock.
  Information about the target is available to the targeting user.
  The user can open fire on the target.
  """

  use Ecspanse.System, lock_components: [IST.Components.Target]

  @impl true
  def run(frame) do
    frame.event_stream
    |> Stream.filter(fn
      %IST.Events.AcquireTargetLock{} -> true
      _ -> false
    end)
    |> Stream.map(fn event ->
      %{
        hunter: Ecspanse.Entity.build(event.hunter_id),
        target: Ecspanse.Entity.build(event.target_id)
      }
    end)
    |> Enum.map(fn %{hunter: hunter, target: target} ->
      {hunter, [{IST.Components.Target, %{target: target}}]}
    end)
    |> Ecspanse.Command.add_components!()
  end
end
