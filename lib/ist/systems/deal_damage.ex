defmodule IST.Systems.DealDamage do
  @moduledoc """
  The target receives and handles the damage.
  - shields take damage
  - hull takes damage


  The hunter takes points for the damage dealt. There is a multiplier for the target's level.


  ATTENTION! A target can take multiple damage events in the same frame, from different enemies.
  Each target needs to handle a list of events, which makes this system more complex and less efficient.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.Shields,
      IST.Components.Hull,
      IST.Components.Level
    ]

  alias Ecspanse.Query
  alias IST.Events.DealDamage, as: DamageEvent

  @impl true
  def run(frame) do
    events =
      frame.event_stream
      |> Stream.filter(fn
        %DamageEvent{} -> true
        _ -> false
      end)
      |> Enum.map(fn %DamageEvent{target_id: target_id, hunter_id: hunter_id} = event ->
        Map.from_struct(event)
        |> Map.put(:target_entity, Ecspanse.Entity.build(target_id))
        |> Map.put(:hunter_entity, Ecspanse.Entity.build(hunter_id))
      end)

    if Enum.any?(events) do
      group_damage(events, frame.token)
    end
  end

  # partition the damage events by target
  # a batch of updates should not update the same target twice
  defp group_damage([], _token), do: :ok

  defp group_damage(events, token) do
    current_events = Enum.uniq_by(events, fn %{target_id: target_id} -> target_id end)
    deal_damage(current_events, token)
    group_damage(events -- current_events, token)
  end

  defp deal_damage(events, token) do
    target_entities = Enum.map(events, fn %{target_entity: entity} -> entity end)

    Query.select(
      {Ecspanse.Entity, IST.Components.Hull, IST.Components.Level, Ecspanse.Component.Children},
      with: [IST.Components.BattleShip],
      for: target_entities
    )
    |> Query.stream(token)
    |> Stream.map(fn {target_entity, hull, target_level, children} ->
      event = Enum.find(events, fn %{target_entity: entity} -> entity == target_entity end)

      evasion_entity =
        Enum.find(children.list, fn entity ->
          Query.has_component?(entity, IST.Components.Evasion, token)
        end)

      {:ok, evasion} = Query.fetch_component(evasion_entity, IST.Components.Evasion, token)

      shields_entity =
        Enum.find(children.list, fn entity ->
          Query.has_component?(entity, IST.Components.Shields, token)
        end)

      {:ok, shields} = Query.fetch_component(shields_entity, IST.Components.Shields, token)

      do_deal_damage(event, evasion, shields, hull, target_level, token)
    end)
    |> Enum.concat()
    |> Ecspanse.Command.update_components!()
  end

  defp do_deal_damage(event, evasion, shields, hull, target_level, token) do
    if hits_the_target?(evasion, event) do
      {new_shields_hp, remaining_damage} = deal_shield_damage(shields, event)

      update_shields_hp = {shields, hp: new_shields_hp}
      update_hull_hp = {hull, hp: max(hull.hp - remaining_damage, 0)}

      modifier = target_level.value
      add_points = min(hull.hp, remaining_damage) * modifier
      update_points = add_hunter_points(event, add_points, token)

      [update_shields_hp, update_hull_hp, update_points]
    else
      []
    end
  end

  defp hits_the_target?(evasion, event) do
    case IST.Util.odds(
           miss: evasion.value,
           hit: event.accuracy
         ) do
      :hit -> true
      :miss -> false
    end
  end

  # weapon shield efficeincy is a percentage
  defp deal_shield_damage(shields, event) do
    efficiency = event.shields_efficiency / 100
    max_damage = event.damage_value * efficiency

    cond do
      max_damage > shields.hp -> {0, event.damage_value - round(shields.hp / efficiency)}
      max_damage < shields.hp -> {shields.hp - round(event.damage_value * efficiency), 0}
      max_damage == shields.hp -> {0, 0}
    end
  end

  defp add_hunter_points(event, points, token) do
    {:ok, hunter_level} = Query.fetch_component(event.hunter_entity, IST.Components.Level, token)

    {hunter_level,
     points: hunter_level.points + points,
     current_level_up_points: hunter_level.current_level_up_points + points}
  end
end
