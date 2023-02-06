defmodule IST.Systems.CheckTargetAlive do
  @moduledoc """
  Check if the targets still exists.
  Otherwise, remove the target component from the entity.
  """
  use Ecspanse.System, lock_components: [IST.Components.Target]

  @impl true
  def run(frame) do
    deleted_entity_ids =
      frame.event_stream
      |> Stream.filter(fn
        %Ecspanse.Event.ComponentDeleted{deleted: %IST.Components.BattleShip{}} -> true
        _ -> false
      end)
      |> Enum.map(fn event ->
        Ecspanse.Query.get_component_entity(event.deleted, frame.token).id
      end)

    if Enum.any?(deleted_entity_ids) do
      Ecspanse.Query.select({IST.Components.Target}, with: [IST.Components.BattleShip])
      |> Ecspanse.Query.stream(frame.token)
      |> Stream.map(fn {target} -> target end)
      |> Enum.filter(fn target -> target.entity.id in deleted_entity_ids end)
      |> Ecspanse.Command.remove_components!()
    end
  end
end
