defmodule ISTWeb.Live.Game do
  @moduledoc """
  The main game live view.
  """

  use ISTWeb, :surface_live_view

  alias ISTWeb.Components.MainMenu, as: MainMenuComponent
  alias ISTWeb.Components.Observer, as: ObserverComponent

  prop socket_connected, :boolean, default: false

  data state, :atom, default: :main_menu, values!: [:main_menu, :observer]

  def handle_event("change_state", %{"state" => state}, socket) do
    {:noreply, assign(socket, state: String.to_existing_atom(state))}
  end
end
