defmodule IST.Systems.BoostShields do
  @moduledoc """
  Adds hit points to the ship's shields.
  Checks if the ship has enough energy to boost shields and consumes it.
  """

  use Ecspanse.System,
    lock_components: [IST.Components.EnergyStorage, IST.Components.Shields],
    event_subscriptions: [IST.Events.BoostShields]

  @impl true
  def run(event, _frame) do
    with {:ok, entity} <- Ecspanse.Query.fetch_entity(event.ship_id) do
      {:ok, energy_component} =
        Ecspanse.Query.fetch_component(entity, IST.Components.EnergyStorage)

      {shields_component, energy_cost_component} =
        Ecspanse.Query.select({IST.Components.Shields, IST.Components.EnergyCost},
          for_children_of: [entity]
        )
        |> Ecspanse.Query.one()

      if energy_component.value >= energy_cost_component.value do
        Ecspanse.Command.update_components!([
          {energy_component, value: energy_component.value - energy_cost_component.value},
          {shields_component, hp: shields_component.hp + shields_component.boost}
        ])
      end
    end
  end
end
