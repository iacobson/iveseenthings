defmodule IST.Systems.CleanLogger do
  @moduledoc """
  Delete battle logger records older than 30 seconds
  """

  use Ecspanse.System
  require Ex2ms

  @impl true
  def run(frame) do
    {:ok, battle_logger_resource} =
      Ecspanse.Query.fetch_resource(IST.Resources.BattleLogger)

    table = battle_logger_resource.ecs_table

    time_limit = System.system_time(:millisecond) - 30_000

    # whatever condition matches with true will be deleted
    f =
      Ex2ms.fun do
        {{event_time, _hunter_id, _target_id}, _event}
        when event_time < ^time_limit ->
          true
      end

    :ets.select_delete(table, f)
  end
end
