defmodule IST.Systems.BotAction do
  @moduledoc """
  Bot decision system.
  This system should not update components, but just take decisions.
  Meaning schedulin(or not) events for the next frame.
  """

  use Ecspanse.System

  alias Ecspanse.Query

  @impl true
  def run(frame) do
    # THIS WILL NEED TO EVOLVE wiith the game implementation
    # for now, just random decisions

    bot_entities =
      Query.select({Ecspanse.Entity}, with: [IST.Components.Bot])
      |> Query.stream()
      |> Stream.map(fn {entity} -> entity end)
      |> Enum.to_list()

    Ecspanse.System.execute_async(
      bot_entities,
      fn bot_entity ->
        decide(bot_entity, frame, bot_entities -- [bot_entity])
      end,
      concurrent: System.schedulers_online() * 4
    )

    # NO QUERY SHOULD BE MANDE FROM HERE ON!
    # IT WILL RESULT IN N+1 !
    # Anithing needed should be queried before and passed as argument to the `decide` function
  end

  defp decide(entity, frame, enemy_entities) do
    case IST.Util.odds(action: 1, wait: 120) do
      :wait ->
        :ok

      :action ->
        action(entity, frame, enemy_entities)
    end
  end

  defp action(entity, frame, enemy_entities) do
    case IST.Util.odds(
           target: 150,
           evasive_maneuvers: 100,
           boost_shields: 80,
           spawn_drone: 50,
           fire_laser: 90,
           fire_railgun: 70,
           fire_missile: 50
         ) do
      :target ->
        acquire_target_lock(entity, enemy_entities)

      :evasive_maneuvers ->
        perform_evasive_maneuvers(entity)

      :boost_shields ->
        boost_shields(entity)

      :spawn_drone ->
        spawn_drone(entity)

      :fire_laser ->
        fire_laser(entity)

      :fire_railgun ->
        fire_railgun(entity)

      :fire_missile ->
        fire_missile(entity)
    end
  end

  defp acquire_target_lock(entity, target_entities) do
    if Enum.any?(target_entities) do
      random_target = Enum.random(target_entities)

      Ecspanse.event(
        {IST.Events.AcquireTargetLock, hunter_id: entity.id, target_id: random_target.id},
        batch_key: random_target.id
      )
    end
  end

  defp perform_evasive_maneuvers(entity) do
    Ecspanse.event(
      {IST.Events.PerformEvasiveManeuvers, ship_id: entity.id},
      batch_key: entity.id
    )
  end

  defp boost_shields(entity) do
    Ecspanse.event(
      {IST.Events.BoostShields, ship_id: entity.id},
      batch_key: entity.id
    )
  end

  defp spawn_drone(entity) do
    Ecspanse.event(
      {IST.Events.SpawnDrone, ship_id: entity.id},
      batch_key: entity.id
    )
  end

  defp fire_laser(entity) do
    Ecspanse.event(
      {IST.Events.FireWeapon, ship_id: entity.id, weapon: :laser},
      batch_key: entity.id
    )
  end

  defp fire_railgun(entity) do
    Ecspanse.event(
      {IST.Events.FireWeapon, ship_id: entity.id, weapon: :railgun},
      batch_key: entity.id
    )
  end

  defp fire_missile(entity) do
    Ecspanse.event(
      {IST.Events.FireWeapon, ship_id: entity.id, weapon: :missile},
      batch_key: entity.id
    )
  end
end
