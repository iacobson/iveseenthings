defmodule ISTWeb.Components.Observer do
  @moduledoc """
  The observer component.
  The player can select another player and observer it playing
  """
  use ISTWeb, :surface_live_component

  alias ISTWeb.Components.PlayerList, as: PlayerListComponent
  alias ISTWeb.Components.Player, as: PlayerComponent

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state
  prop token, :string, from_context: :token

  data selected_player, :string, default: nil

  @impl true
  def handle_event("select_player", %{"player_id" => id}, socket) do
    socket = assign(socket, selected_player: id)
    {:noreply, socket}
  end
end
