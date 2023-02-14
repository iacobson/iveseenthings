defmodule IST.Systems.DestroyShip do
  @moduledoc """
  When the ship's hull reaches zero, the ship is destroyed.
  It destroys also all children entities.
  """

  use Ecspanse.System

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, frame) do
    ship_entities =
      events
      |> Stream.filter(fn
        %Ecspanse.Event.ComponentUpdated{updated: %IST.Components.Hull{hp: 0}} -> true
        _ -> false
      end)
      |> Stream.map(fn event ->
        Ecspanse.Query.get_component_entity(event.updated, frame.token)
      end)
      |> Enum.to_list()

    if Enum.any?(ship_entities) do
      Ecspanse.Command.despawn_entities_and_children!(ship_entities)
    end
  end
end
