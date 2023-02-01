defmodule ISTWeb.Components.Player do
  @moduledoc """
  The Player
  Depending on the game state:
  - :observer -> the selected player
  - :play -> THE player
  """
  use ISTWeb, :surface_live_component

  alias __MODULE__
  alias Ecspanse.Query
  alias Ecspanse.Entity
  alias IST.Components

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state
  prop token, :string, from_context: :token

  @doc "The BattleShip entity ID"
  prop selected, :string, default: nil

  data player, :struct, default: nil

  defstruct id: nil, name: nil, type: nil

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> fetch_player()

    {:ok, socket}
  end

  defp fetch_player(socket) do
    case socket.assigns do
      %{state: :observer} ->
        entity = Entity.build(socket.assigns.selected)

        player = build_player(entity, socket.assigns.token)
        assign(socket, player: player)

      %{state: :play} ->
        # TODO
        # player = build_player(entity, socket.assigns.token)
        socket
    end
  end

  defp build_player(entity, token) do
    {player, children} =
      Query.select(
        {Components.BattleShip, Ecspanse.Component.Children},
        for: [entity]
      )
      |> Query.one(token)

    %Player{id: entity.id, name: String.slice(player.name, 0, 13)}
    |> add_type(entity, token)
  end

  defp add_type(player, entity, token) do
    if Query.has_component?(entity, Components.Human, token) do
      Map.put(player, :type, "human")
    else
      Map.put(player, :type, "bot")
    end
  end
end
