defmodule IST.Systems.AddOrRemoveBots do
  @moduledoc """
  Fill the target number of bots. Or remove the excess.
  It is limited ot one operation per frame, not to create big spikes.
  Eg. If the bots were destroyed, this will spawn new ones.
  """

  use Ecspanse.System
  alias Ecspanse.Query

  @impl true
  def run(_frame) do
    target_player_count = Application.get_env(:iveseenthings, :player_count)

    current_player_count =
      Query.select({Ecspanse.Entity},
        with: [IST.Components.BattleShip]
      )
      |> Query.stream()
      |> Enum.count()

    if current_player_count < target_player_count do
      IST.Systems.Helper.spawn_bot_entity()
    end
  end
end
