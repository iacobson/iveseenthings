defmodule IST.Systems.TargetLock do
  @moduledoc """
  Acquires a target lock.
  Information about the target is available to the targeting user.
  The user can open fire only on a the target.
  """

  use Ecspanse.System,
    lock_components: [
      Ecspanse.Component.Children,
      Ecspanse.Component.Parents,
      IST.Components.Target
    ]

  alias Ecspanse.Query

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
      delete_existing_targets(hunter_entities, frame.token)

      # creating just the entity of type Target, will automatically add to the children and parents (target or hunter!)
      create_target_entities(hunter_target_entities)
    end
  end

  defp delete_existing_targets(hunter_entities, token) do
    Query.select({Ecspanse.Component.Children}, for: hunter_entities)
    |> Query.stream(token)
    |> Stream.map(fn {children} -> children.list end)
    |> Stream.concat()
    |> Stream.filter(fn children_entity ->
      Query.is_type?(children_entity, IST.Components.Target, token)
    end)
    |> Enum.to_list()
    |> Ecspanse.Command.despawn_entities!()
  end

  defp create_target_entities(hunter_target_entities) do
    hunter_target_entities
    |> Enum.map(fn %{hunter: hunter, target: target} ->
      {Ecspanse.Entity,
       components: [IST.Components.Target], children: [target], parents: [hunter]}
    end)
    |> Ecspanse.Command.spawn_entities!()
  end
end
