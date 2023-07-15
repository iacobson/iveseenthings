defmodule ISTWeb.Live.Game do
  @moduledoc """
  The main game live view.
  """

  use ISTWeb, :surface_live_view

  alias ISTWeb.Components.MainMenu, as: MainMenuComponent
  alias ISTWeb.Components.GameOver, as: GameOverComponent
  alias ISTWeb.Components.Observer, as: ObserverComponent
  alias ISTWeb.Components.Play, as: PlayComponent

  prop socket_connected, :boolean, default: false
  prop user_id, :string, default: nil

  data state, :atom, default: :main_menu, values!: [:main_menu, :observer, :play, :game_over]

  # Live View and Live Component state fetching
  @fps 4

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns do
      %{socket_connected: true} ->
        socket = Surface.Components.Context.put(socket, state: socket.assigns.state)
        send(self(), :tick)

        # This is used to determine if any human is connected to the game
        ISTWeb.Presence.track(self(), "iveseenthings", socket.assigns.user_id, %{})

        {:ok, socket}

      _ ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("change_state", %{"state" => state}, socket) do
    state = String.to_existing_atom(state)
    socket = update_state(state, socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:change_state, state}, socket) do
    socket = update_state(state, socket)
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, round(1000 / @fps))

    socket =
      socket
      |> Surface.Components.Context.put(tick: System.os_time(:millisecond))

    {:noreply, socket}
  end

  defp update_state(new_state, socket) do
    socket
    |> assign(state: new_state)
    |> Surface.Components.Context.put(state: new_state)
  end
end
