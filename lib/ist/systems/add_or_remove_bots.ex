defmodule IST.Systems.AddOrRemoveBots do
  @moduledoc """
  Fill the target number of bots. Or remove the excess.
  It is limited ot one operation per frame, not to create big spikes.
  Eg. If the bots were destroyed, this will spawn new ones.
  """

  use Ecspanse.System
  alias Ecspanse.Query

  @impl true
  def run(tick) do
    target_player_count = Application.get_env(:iveseenthings, :player_count)

    current_player_count =
      Query.select({Ecspanse.Entity},
        with: [IST.Components.BattleShip]
      )
      |> Query.stream(tick.token)
      |> Enum.count()

    if current_player_count < target_player_count do
      IST.Systems.Helper.spawn_bot_entity()
    end

    # TODO:
    # - after implementing the XP system,
    # if the current player count is higher than the target,
    # remove the bots with the lowest XP.
    # - first chedk if there are any bots left in the game

    # keep in mind when creating the join player system
    # allow join only for player_count + 1
    # if the games ends with 101 human players, it will not accept new players
  end
end
