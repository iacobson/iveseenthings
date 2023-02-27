defmodule IST do
  @moduledoc """
  GenServer that coordinates the init of the game
  """

  use GenServer

  def child_spec(_attrs) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :permanent
    }
  end

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(attrs) do
    {:ok, attrs, {:continue, :start_game}}
  end

  def handle_continue(:start_game, state) do
    # This is the only world in thig game.
    {:ok, _token} =
      Ecspanse.new(IST.Game,
        name: IST.Game,
        dyn_sup: IST.DynamicSupervisor
      )

    {:noreply, state}
  end
end
