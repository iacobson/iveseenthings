defmodule IST.Systems.LevelUp do
  @moduledoc """
  Checks if the player has enough points to level up.
  Sets up the next level points.

  On level-up:
  - Adds 10 * level value hull hp.
  - Adds 3 * level value energy storage.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.Level,
      IST.Components.Hull,
      IST.Components.EnergyStorage
    ],
    event_subscriptions: [IST.Events.GotPoints]

  alias Ecspanse.Query

  @impl true
  def run(%IST.Events.GotPoints{ship_id: ship_id}, _frame) do
    with {:ok, ship_entity} <- Query.fetch_entity(ship_id),
         {:ok, level} <- Query.fetch_component(ship_entity, IST.Components.Level),
         true <- level_up?(level),
         {:ok, {hull, energy_storage}} <-
           Query.fetch_components(
             ship_entity,
             {IST.Components.Hull, IST.Components.EnergyStorage}
           ) do
      level_value = level.value + 1

      level_update =
        {level,
         value: level_value,
         current_level_up_points: level.current_level_up_points - level.next_level_up_points,
         next_level_up_points: IST.Util.fibo_calculate(level.base, level_value)}

      hull_update = {hull, hp: hull.hp + 15 * level_value}

      enrgy_update = {energy_storage, value: energy_storage.value + 5 * level_value}

      Ecspanse.Command.update_components!([level_update, hull_update, enrgy_update])
    end
  end

  def level_up?(level) do
    level.current_level_up_points >= level.next_level_up_points
  end
end
