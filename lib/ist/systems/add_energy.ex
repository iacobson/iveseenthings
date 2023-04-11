defmodule IST.Systems.AddEnergy do
  @moduledoc """
  When the counter reaches zero, add energy to the ship and resets back the counter.
  """

  use Ecspanse.System,
    lock_components: [IST.Components.EnergyStorage],
    events_subscription: [IST.Events.EnergyTimerComplete]

  @impl true
  def run(%IST.Events.EnergyTimerComplete{} = event, frame) do
    {:ok, energy_storage_component} =
      Ecspanse.Query.fetch_component(event.entity, IST.Components.EnergyStorage, frame.token)

    Ecspanse.Command.update_component!(energy_storage_component,
      value: energy_storage_component.value + 1
    )
  end
end
