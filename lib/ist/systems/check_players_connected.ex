defmodule IST.Systems.CheckPlayersConnected do
  @moduledoc """
  Checks the Phoenix presence if there are any players connected.
  Otherwise pause the game
  """

  use Ecspanse.System

  @impl true
  def run(frame) do
    users = Phoenix.Presence.list(ISTWeb.Presence, "iveseenthings")

    {:ok, game_state} = Ecspanse.Query.fetch_resource(Ecspanse.Resource.State)

    if users == %{} do
      Ecspanse.Command.update_resource!(game_state, value: :pause)
    else
      Ecspanse.Command.update_resource!(game_state, value: :play)
    end
  end
end
