defmodule ISTWeb.Components.Observer do
  @moduledoc """
  The observer component.
  The player can select another player and observer it playing
  """
  use ISTWeb, :surface_live_component

  alias Ecspanse.Query

  alias ISTWeb.Components.BattleLog, as: BattleLogComponent
  alias ISTWeb.Components.Player, as: PlayerComponent
  alias ISTWeb.Components.PlayerList, as: PlayerListComponent
  alias ISTWeb.Components.TargetLock, as: TargetLockComponent
  alias ISTWeb.Components.TargetedBy, as: TargetedByComponent

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state

  data selected_player, :string, default: nil
  data target_player, :string, default: nil

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> fetch_target_player()

    {:ok, socket}
  end

  @impl true
  def handle_event("select_player", %{"player_id" => nil}, socket) do
    {:noreply, socket}
  end

  def handle_event("select_player", %{"player_id" => id}, socket) do
    entity = Ecspanse.Entity.build(id)

    if Query.has_component?(entity, IST.Components.BattleShip) do
      socket = assign(socket, selected_player: id)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp fetch_target_player(socket) do
    case socket.assigns.selected_player do
      nil ->
        assign(socket, target_player: nil)

      player_id ->
        entity = Ecspanse.Entity.build(player_id)

        with children when is_list(children) and length(children) > 0 <-
               Query.list_children(entity),
             %Ecspanse.Entity{} = target_entity <-
               Enum.find(children, fn child ->
                 Query.is_type?(child, IST.Components.Target)
               end),
             # Alaways need to check if the target is still alive
             [target_ship_entity] <- Query.list_children(target_entity) do
          assign(socket, target_player: target_ship_entity.id)
        else
          _ ->
            assign(socket, target_player: nil)
        end
    end
  end
end
