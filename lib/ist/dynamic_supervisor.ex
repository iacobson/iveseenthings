defmodule IST.DynamicSupervisor do
  @moduledoc """
  Worlds supervisor
  """

  use DynamicSupervisor

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :permanent,
      type: :supervisor
    }
  end

  # API

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # SERVER

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
