defmodule IST.ETSParent do
  @moduledoc """
  Genserver that serves as parent for in game ETS tables.
  Ecspanse uses short lived tasks for its systems and they cannot create ETS tables on their own.
  Using the `{:heir, pid, nil}` options when creating the ETS.


  It should not restart, as it will be re-created from the system
  """

  use GenServer

  def child_spec(_data) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :temporary
    }
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_data) do
    {:ok, %{}}
  end

  def handle_info({:"ETS-TRANSFER", _, _, _}, state) do
    {:noreply, state}
  end

  def handle_info({:link_world, world_token}, state) do
    # linking with the world process.
    # If the world process dies, this process should and associated ETS should termiante as well
    {:ok, %{world_pid: world_pid}} = Ecspanse.fetch_world_data(world_token)
    Process.link(world_pid)
    {:noreply, state}
  end
end
