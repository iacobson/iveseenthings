defmodule IST.Systems.DestroyShip do
  @moduledoc """
  When the ship's hull reaches zero, the ship is destroyed.
  It destroys also all children entities.
  """

  use Ecspanse.System

  @impl true
  def run(_frame) do
    destroyed_ship_entities =
      IST.Components.Hull.list()
      |> Stream.filter(fn
        %IST.Components.Hull{hp: 0} -> true
        _ -> false
      end)
      |> Stream.map(fn hull ->
        Ecspanse.Query.get_component_entity(hull)
      end)
      |> Enum.to_list()

    if Enum.any?(destroyed_ship_entities) do
      Ecspanse.Command.despawn_entities_and_descendants!(destroyed_ship_entities)
    end
  end
end
