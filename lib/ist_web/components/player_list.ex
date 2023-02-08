defmodule ISTWeb.Components.PlayerList do
  @moduledoc """
  A list of players.
  Depending on the game state:
  - :observer -> all the players in the game
  - :play -> all the players in the same location as the player, except the player itself
  """
  use ISTWeb, :surface_live_component

  alias Ecspanse.Query
  alias Ecspanse.Entity
  alias IST.Components
  alias Phoenix.LiveView.JS

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state
  prop token, :string, from_context: :token

  prop select_player_event, :event
  prop selected, :string, default: nil

  data players, :list, default: []
  data fps, :decimal, default: 0.0

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> fetch_players()
      |> update_fps()

    {:ok, socket}
  end

  defp fetch_players(socket) do
    case socket.assigns do
      %{state: :observer} ->
        players = get_all_players(socket.assigns.token)
        assign(socket, players: players)

      %{state: :play} ->
        # TODO
        socket
    end
  end

  defp get_all_players(token) do
    Query.select({Entity, Components.BattleShip, opt: Components.Human, opt: Components.Bot})
    |> Query.stream(token)
    |> Stream.map(fn
      {entity, battle_ship, human, bot} ->
        player_type =
          case {human, bot} do
            {%Components.Human{}, nil} -> "human"
            {nil, %Components.Bot{}} -> "bot"
          end

        %{
          id: entity.id,
          name: String.slice(battle_ship.name, 0, 13),
          type: player_type
        }
    end)
  end

  defp update_fps(socket) do
    {:ok, fps_resource} =
      Ecspanse.Query.fetch_resource(Ecspanse.Resource.FPS, socket.assigns.token)

    assign(socket, fps: fps_resource.value)
  end
end
