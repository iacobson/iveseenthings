defmodule IST.Debug do
  @moduledoc """
  Genserver to be used as debugging system.
  Being promoted to an Ecspanse System, would be able to execute Commands
  without being scheduled.

  The same approach can be used in Dev environments to change the state of a running game.
  """
  use GenServer
  alias __MODULE__

  defstruct [:token]

  def add_energy(entity, amount) do
    GenServer.call(__MODULE__, {:add_energy, entity, amount})
  end

  def start_link(token) do
    GenServer.start_link(__MODULE__, token, name: __MODULE__)
  end

  def init(token) do
    Ecspanse.System.debug(token)
    {:ok, %Debug{token: token}}
  end

  def handle_call({:add_energy, entity, amount}, _from, state) do
    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(entity, IST.Components.EnergyStorage, state.token)

    Ecspanse.Command.update_component!(energy_component, value: energy_component.value + amount)
    {:reply, :ok, state}
  end
end
