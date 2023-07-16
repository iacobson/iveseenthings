defmodule IST.Systems.DealDamage do
  @moduledoc """
  The target receives and handles the damage.
  - shields take damage
  - hull takes damage


  The hunter takes points for the damage dealt. There is a multiplier for the target's level.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.Shields,
      IST.Components.Drones,
      IST.Components.Hull,
      IST.Components.Level
    ]

  alias Ecspanse.Query
  alias IST.Events.DealDamage, as: DamageEvent

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, _frame) do
    events =
      events
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
      deal_damage(events)
    end
  end

  defp deal_damage(events) do
    target_entities = Enum.map(events, fn %{target_entity: entity} -> entity end)

    Query.select(
      {Ecspanse.Entity, IST.Components.Hull, IST.Components.Level, Ecspanse.Component.Children},
      with: [IST.Components.BattleShip],
      for: target_entities
    )
    |> Query.stream()
    |> Stream.map(fn {target_entity, hull, target_level, children} ->
      event = Enum.find(events, fn %{target_entity: entity} -> entity == target_entity end)

      do_deal_damage(event, hull, target_level, children.entities)
    end)
    |> Enum.to_list()
    |> List.flatten()
    |> Ecspanse.Command.update_components!()
  end

  defp do_deal_damage(event, hull, target_level, children_entities) do
    evasion_entity =
      Enum.find(children_entities, fn entity ->
        Query.has_component?(entity, IST.Components.Evasion)
      end)

    {:ok, evasion} = Query.fetch_component(evasion_entity, IST.Components.Evasion)

    drone_entity =
      Enum.find(children_entities, fn entity ->
        Query.has_component?(entity, IST.Components.Drones)
      end)

    {:ok, drones} = Query.fetch_component(drone_entity, IST.Components.Drones)

    {:ok, battle_logger_resource} =
      Ecspanse.Query.fetch_resource(IST.Resources.BattleLogger)

    battle_logger_table = battle_logger_resource.ecs_table

    if hits_the_target?(evasion, event, battle_logger_table) and
         pass_the_drones?(drones, event, battle_logger_table) do
      shields_entity =
        Enum.find(children_entities, fn entity ->
          Query.has_component?(entity, IST.Components.Shields)
        end)

      {:ok, shields} = Query.fetch_component(shields_entity, IST.Components.Shields)
      {new_shields_hp, hull_damage} = deal_shield_damage(shields, event)

      shields_damage = shields.hp - new_shields_hp

      :ets.insert(
        battle_logger_table,
        {{System.os_time(:millisecond), event.hunter_id, event.target_id},
         %{
           result: :hit,
           damage_type: event.damage_type,
           shields_damage: shields_damage,
           hull_damage: hull_damage
         }}
      )

      update_shields_hp = {shields, hp: new_shields_hp}
      update_hull_hp = {hull, hp: max(hull.hp - hull_damage, 0)}

      modifier = target_level.value
      add_points = min(hull.hp, hull_damage) * modifier
      update_points = add_hunter_points(event, add_points)

      update_drones = destroy_a_drone(hull_damage, drones)

      [update_shields_hp, update_hull_hp, update_points, update_drones] |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp hits_the_target?(evasion, event, battle_logger_table) do
    case IST.Util.odds(
           miss: evasion.value,
           hit: event.accuracy
         ) do
      :hit ->
        true

      :miss ->
        :ets.insert(
          battle_logger_table,
          {{System.os_time(:millisecond), event.hunter_id, event.target_id},
           %{result: :miss, damage_type: event.damage_type}}
        )

        false
    end
  end

  # the Point Defense Drone can intercept missiles and railgun shots
  defp pass_the_drones?(drones, %{damage_type: :railgun} = event, battle_logger_table) do
    case IST.Util.odds(
           stop: drones.projectile_defense * drones.count,
           hit: event.accuracy
         ) do
      :hit ->
        true

      :stop ->
        :ets.insert(
          battle_logger_table,
          {{System.os_time(:millisecond), event.hunter_id, event.target_id},
           %{result: :stop, damage_type: event.damage_type}}
        )

        false
    end
  end

  defp pass_the_drones?(drones, %{damage_type: :missile} = event, battle_logger_table) do
    case IST.Util.odds(
           stop: drones.missile_defense * drones.count,
           hit: event.accuracy
         ) do
      :hit ->
        true

      :stop ->
        :ets.insert(
          battle_logger_table,
          {{System.os_time(:millisecond), event.hunter_id, event.target_id},
           %{result: :stop, damage_type: event.damage_type}}
        )

        false
    end
  end

  defp pass_the_drones?(_drones, _event, _), do: true

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

  # destroy a drone if the ship hull receives any damage
  defp destroy_a_drone(damage, drones) do
    if damage > 0 and drones.count > 0 do
      {drones, count: drones.count - 1}
    else
      nil
    end
  end

  defp add_hunter_points(event, points) do
    {:ok, hunter_level} = Query.fetch_component(event.hunter_entity, IST.Components.Level)

    {hunter_level,
     points: hunter_level.points + points,
     current_level_up_points: hunter_level.current_level_up_points + points}
  end
end
