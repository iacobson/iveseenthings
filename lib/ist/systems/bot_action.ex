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
      |> Query.stream(frame.token)
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
           target: 100,
           evasive_maneuvers: 30,
           boost_shields: 80,
           fire_laser: 40,
           fire_railgun: 60,
           fire_missile: 100
         ) do
      :target ->
        acquire_target_lock(entity, frame, enemy_entities)

      :evasive_maneuvers ->
        perform_evasive_maneuvers(entity, frame)

      :boost_shields ->
        boost_shields(entity, frame)

      :fire_laser ->
        fire_laser(entity, frame)

      :fire_railgun ->
        fire_railgun(entity, frame)

      :fire_missile ->
        fire_missile(entity, frame)
    end
  end

  defp acquire_target_lock(entity, frame, target_entities) do
    if Enum.any?(target_entities) do
      random_target = Enum.random(target_entities)

      Ecspanse.event(
        {IST.Events.AcquireTargetLock, entity.id,
         hunter_id: entity.id, target_id: random_target.id},
        frame.token
      )
    end
  end

  defp perform_evasive_maneuvers(entity, frame) do
    Ecspanse.event(
      {IST.Events.PerformEvasiveManeuvers, entity.id, ship_id: entity.id},
      frame.token
    )
  end

  defp boost_shields(entity, frame) do
    Ecspanse.event(
      {IST.Events.BoostShields, entity.id, ship_id: entity.id},
      frame.token
    )
  end

  defp fire_laser(entity, frame) do
    Ecspanse.event(
      {IST.Events.FireWeapon, entity.id, ship_id: entity.id, weapon: :laser},
      frame.token
    )
  end

  defp fire_railgun(entity, frame) do
    Ecspanse.event(
      {IST.Events.FireWeapon, entity.id, ship_id: entity.id, weapon: :railgun},
      frame.token
    )
  end

  defp fire_missile(entity, frame) do
    Ecspanse.event(
      {IST.Events.FireWeapon, entity.id, ship_id: entity.id, weapon: :missile},
      frame.token
    )
  end
end
