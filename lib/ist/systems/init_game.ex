defmodule IST.Systems.InitGame do
  @moduledoc """
  Mark game ready to play
  """

  use Ecspanse.System

  @impl true
  def run(frame) do
    {:ok, world_state} = Ecspanse.Query.fetch_resource(Ecspanse.Resource.State, frame.token)
    Ecspanse.Command.update_resource!(world_state, value: :play)

    # The ETS is started from a Task, so it is temporary.
    # Creating a dedicated server that would act as parent for the ETS table
    {:ok, ets_heir_pid} = DynamicSupervisor.start_child(IST.DynamicSupervisor, {IST.ETSParent, []})
    # link the world process with the ETS parent process
    send(ets_heir_pid, {:link_world, frame.token})

    battle_logger_ecs_table =
      :ets.new(String.to_atom("battle_log:#{UUID.uuid4()}"), [
        :ordered_set,
        :public,
        :named_table,
        {:heir, ets_heir_pid, nil},
        read_concurrency: true,
        write_concurrency: :auto
      ])

    Ecspanse.Command.insert_resource!({IST.Resources.BattleLogger, ecs_table: battle_logger_ecs_table})
  end
end
