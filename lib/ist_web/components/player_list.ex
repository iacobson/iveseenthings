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

  prop current_player, :string, default: nil
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
        players = get_all_players()
        assign(socket, players: players)

      %{state: :play} ->
        players =
          get_all_players()
          |> Enum.reject(&(&1.id == socket.assigns.current_player))

        assign(socket, players: players)
    end
  end

  defp get_all_players() do
    Query.select(
      {Entity, Components.BattleShip, Components.Level,
       opt: Components.Human, opt: Components.Bot}
    )
    |> Query.stream()
    |> Stream.map(fn
      {entity, battle_ship, level, human, bot} ->
        player_type =
          case {human, bot} do
            {%Components.Human{}, nil} -> "human"
            {nil, %Components.Bot{}} -> "bot"
          end

        %{
          id: entity.id,
          name: String.slice(battle_ship.name, 0, 13),
          type: player_type,
          level: level.value,
          points: level.points
        }
    end)
    |> Enum.sort_by(& &1.points, &>=/2)
  end

  defp update_fps(socket) do
    {:ok, fps_resource} =
      Ecspanse.Query.fetch_resource(Ecspanse.Resource.FPS)

    assign(socket, fps: fps_resource.value)
  end
end
