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
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, frame) do
    hunter_target_entities =
      events
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
      |> Stream.filter(fn %{hunter: hunter, target: target} ->
        # Validate if the hunter and target exist
        Query.has_component?(hunter, IST.Components.BattleShip) &&
          Query.has_component?(target, IST.Components.BattleShip)
      end)
      |> Enum.to_list()

    # remove existing targets
    hunter_entities = Enum.map(hunter_target_entities, fn %{hunter: hunter} -> hunter end)

    if Enum.any?(hunter_entities) do
      delete_existing_targets(hunter_entities)

      # creating just the entity of type Target, will automatically add to the children and parents (target or hunter!)
      create_target_entities(hunter_target_entities)
    end
  end

  defp delete_existing_targets(hunter_entities) do
    Query.select({Ecspanse.Entity},
      with: [IST.Components.Target],
      for_children_of: hunter_entities
    )
    |> Query.stream()
    |> Stream.map(fn {entity} -> entity end)
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
