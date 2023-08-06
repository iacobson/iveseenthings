defmodule IST.Systems.AddEnergy do
  @moduledoc """
  When the counter reaches zero, add energy to the ship.
  """

  use Ecspanse.System,
    lock_components: [IST.Components.EnergyStorage],
    event_subscriptions: [IST.Events.EnergyTimerComplete]

  @impl true
  def run(%IST.Events.EnergyTimerComplete{entity_id: entity_id}, _frame) do
    # Making sure the entity is still alive
    with {:ok, entity} <- Ecspanse.Query.fetch_entity(entity_id) do
      {:ok, energy_storage_component} =
        Ecspanse.Query.fetch_component(entity, IST.Components.EnergyStorage)

      Ecspanse.Command.update_component!(energy_storage_component,
        value: energy_storage_component.value + 1
      )
    end
  end
end
