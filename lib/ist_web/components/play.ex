defmodule ISTWeb.Components.Play do
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

  prop user_id, :string, from_context: :user_id

  data player_created, :boolean, default: false
  data player_dead, :boolean, default: false
  data current_player, :string, default: nil
  data target_player, :string, default: nil

  # Create the player
  def update(assigns, %{assigns: %{player_created: false}} = socket) do
    socket =
      socket
      |> assign(assigns)
      |> create_player()

    {:ok, socket}
  end

  # The player exists
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> check_player_alive()
      |> fetch_target_player()

    {:ok, socket}
  end

  @impl true
  def handle_event("select_player", %{"player_id" => nil}, socket) do
    {:noreply, socket}
  end

  def handle_event("select_player", %{"player_id" => target_id}, socket) do
    Ecspanse.event(
      {IST.Events.AcquireTargetLock,
       hunter_id: socket.assigns.current_player, target_id: target_id},
      batch_key: target_id
    )

    {:noreply, socket}
  end

  defp create_player(socket) do
    Ecspanse.event(
      {IST.Events.AddPlayer, player_id: socket.assigns.user_id},
      batch_key: socket.assigns.user_id
    )

    assign(socket, player_created: true)
  end

  defp check_player_alive(socket) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(socket.assigns.user_id),
         true <- Ecspanse.Query.has_component?(entity, IST.Components.Human) do
      assign(socket, player_dead: false, current_player: socket.assigns.user_id)
    else
      _ ->
        send(self(), {:change_state, :game_over})
        assign(socket, player_dead: true, current_player: nil)
    end
  end

  defp fetch_target_player(%{assigns: %{current_player: nil}} = socket) do
    socket
  end

  defp fetch_target_player(socket) do
    case socket.assigns.current_player do
      nil ->
        assign(socket, target_player: nil)

      player_id ->
        with {:ok, entity} <- Ecspanse.Entity.fetch(player_id),
             children when is_list(children) and length(children) > 0 <-
               Query.list_children(entity),
             %Ecspanse.Entity{} = target_entity <-
               Enum.find(children, fn child ->
                 Query.has_component?(child, IST.Components.Target)
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
