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
    ]

  alias Ecspanse.Query

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, _frame) do
    ship_entities =
      events
      |> Stream.filter(fn
        %Ecspanse.Event.ComponentUpdated{
          component: %IST.Components.Level{
            current_level_up_points: current_points,
            next_level_up_points: next_points
          }
        }
        when current_points >= next_points ->
          true

        _ ->
          false
      end)
      |> Stream.map(fn event ->
        Ecspanse.Query.get_component_entity(event.component)
      end)
      |> Enum.to_list()

    if Enum.any?(ship_entities) do
      level_up(ship_entities)
    end
  end

  # re-fetching the Level component is case it was updated
  defp level_up(ship_entities) do
    Query.select(
      {IST.Components.Level, IST.Components.Hull, IST.Components.EnergyStorage},
      with: [IST.Components.BattleShip],
      for: ship_entities
    )
    |> Query.stream()
    |> Stream.filter(fn {level, _hull, _energy} ->
      level.current_level_up_points >= level.next_level_up_points
    end)
    |> Enum.map(fn {level, hull, energy} ->
      level_value = level.value + 1

      level_update =
        {level,
         value: level_value,
         current_level_up_points: level.current_level_up_points - level.next_level_up_points,
         next_level_up_points: IST.Util.fibo_calculate(level.base, level_value)}

      hull_update = {hull, hp: hull.hp + 15 * level_value}

      enrgy_update = {energy, value: energy.value + 5 * level_value}

      [level_update, hull_update, enrgy_update]
    end)
    |> Enum.concat()
    |> Ecspanse.Command.update_components!()
  end
end
