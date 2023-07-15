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
    entity = Ecspanse.Entity.build(socket.assigns.player)

    targeting_ship_entities =
      Query.list_parents(entity)
      |> Stream.filter(fn entity ->
        Query.is_type?(entity, Components.Target)
      end)
      |> Stream.map(fn entity ->
        Query.list_parents(entity)
      end)
      |> Enum.concat()

    if Enum.any?(targeting_ship_entities) do
      assign_targeting_enemies(socket, targeting_ship_entities)
    else
      assign(socket, targeting_enemies: [])
    end
  end

  defp assign_targeting_enemies(socket, targeting_ship_entities) do
    targeting_enemies =
      Query.select(
        {Entity, Components.BattleShip, opt: Components.Human, opt: Components.Bot},
        for: targeting_ship_entities
      )
      |> Query.stream()
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

    assign(socket, targeting_enemies: targeting_enemies)
  end
end
