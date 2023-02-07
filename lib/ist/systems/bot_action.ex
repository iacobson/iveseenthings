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
    case IST.Util.odds(action: 1, wait: 180) do
      :wait ->
        :ok

      :action ->
        action(entity, frame, enemy_entities)
    end
  end

  defp action(entity, frame, enemy_entities) do
    acquire_target_lock(entity, frame, enemy_entities)
  end

  defp acquire_target_lock(entity, frame, target_entities) do
    if Enum.any?(target_entities) do
      random_target = Enum.random(target_entities)

      Ecspanse.event(
        frame.token,
        {IST.Events.AcquireTargetLock, entity.id,
         hunter_id: entity.id, target_id: random_target.id}
      )
    end
  end
end
