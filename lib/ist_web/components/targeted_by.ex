defmodule ISTWeb.Components.TargetedBy do
  @moduledoc """
  Enemies targeting the player.
  """
  use ISTWeb, :surface_live_component

  alias Ecspanse.Query
  alias Ecspanse.Entity
  alias IST.Components
  alias Phoenix.LiveView.JS

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state
  prop token, :string, from_context: :token

  prop player, :string, default: nil
  prop select_player_event, :event
  prop selected, :string, default: nil

  data targeting_enemies, :list, default: []

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> fetch_targeting_enemies()

    {:ok, socket}
  end

  defp fetch_targeting_enemies(socket) do
    targeting_enemeies =
      Query.select(
        {Entity, Components.BattleShip, Components.Target,
         opt: Components.Human, opt: Components.Bot}
      )
      |> Query.stream(socket.assigns.token)
      |> Stream.filter(fn
        {_entity, _battle_ship, target, _human, _bot} ->
          target.entity.id == socket.assigns.player
      end)
      |> Stream.map(fn
        {entity, battle_ship, _target, human, bot} ->
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

    assign(socket, targeting_enemies: targeting_enemeies)
  end
end
