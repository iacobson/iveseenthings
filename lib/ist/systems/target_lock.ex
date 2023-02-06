defmodule IST.Systems.TargetLock do
  @moduledoc """
  Acquires a target lock.
  Information about the target is available to the targeting user.
  The user can open fire on the target.
  """

  use Ecspanse.System, lock_components: [IST.Components.Target]

  @impl true
  def run(frame) do
    hunter_target_entities =
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
      |> Enum.to_list()

    # remove existing targets
    hunter_entities = Enum.map(hunter_target_entities, fn %{hunter: hunter} -> hunter end)

    if Enum.any?(hunter_entities) do
      Ecspanse.Query.select({IST.Components.Target}, for: hunter_entities)
      |> Ecspanse.Query.stream(frame.token)
      |> Stream.map(fn {target} -> target end)
      |> Enum.to_list()
      |> Ecspanse.Command.remove_components!()

      # Acquire new target
      hunter_target_entities
      |> Enum.map(fn %{hunter: hunter, target: target} ->
        {hunter, [{IST.Components.Target, entity: target}]}
      end)
      |> Ecspanse.Command.add_components!()
    end
  end
end
