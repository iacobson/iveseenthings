defmodule IST.Debug do
  @moduledoc """
  Genserver to be used as debugging system.
  Being promoted to an Ecspanse System, would be able to execute Commands
  without being scheduled.

  The same approach can be used in Dev environments to change the state of a running game.
  """
  use GenServer

  def add_energy(entity, amount) do
    GenServer.call(__MODULE__, {:add_energy, entity, amount})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    Ecspanse.System.debug()
    {:ok, %{}}
  end

  def handle_call({:add_energy, entity, amount}, _from, state) do
    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(entity, IST.Components.EnergyStorage)

    Ecspanse.Command.update_component!(energy_component, value: energy_component.value + amount)
    {:reply, :ok, state}
  end
end
