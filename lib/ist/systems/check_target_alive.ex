defmodule IST.Systems.CheckTargetAlive do
  @moduledoc """
  Check if the targets still exists.
  Otherwise, remove the target component from the entity.
  """
  use Ecspanse.System,
    lock_components: [
      Ecspanse.Component.Children,
      Ecspanse.Component.Parents,
      IST.Components.Target
    ]

  alias Ecspanse.Query

  @impl true
  def run(_frame) do
    Query.select({Ecspanse.Entity, Ecspanse.Component.Children, Ecspanse.Component.Parents},
      with: [IST.Components.Target]
    )
    |> Query.stream()
    |> Stream.filter(fn {_entity, children, parents} ->
      Enum.empty?(children.entities) || Enum.empty?(parents.entities)
    end)
    |> Enum.map(fn {entity, _children, _parents} -> entity end)
    |> Ecspanse.Command.despawn_entities!()
  end
end
