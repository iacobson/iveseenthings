defmodule ISTWeb.Live.Game do
  @moduledoc """
  The main game live view.
  """

  use ISTWeb, :surface_live_view

  alias ISTWeb.Components.MainMenu, as: MainMenuComponent
  alias ISTWeb.Components.Observer, as: ObserverComponent

  prop socket_connected, :boolean, default: false
  prop token, :string, default: nil
  prop user_id, :string, default: nil

  data state, :atom, default: :main_menu, values!: [:main_menu, :observer]

  # Live View and Live Component state fetching
  @fps 4

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns do
      %{socket_connected: true} ->
        socket = Surface.Components.Context.put(socket, state: socket.assigns.state)
        send(self(), :tick)

        ISTWeb.Presence.track(self(), "iveseenthings", socket.assigns.user_id, %{})

        {:ok, socket}

      _ ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_event("change_state", %{"state" => state}, socket) do
    state = String.to_existing_atom(state)

    socket =
      socket
      |> assign(state: state)
      |> Surface.Components.Context.put(state: state)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, round(1000 / @fps))

    socket =
      socket
      |> Surface.Components.Context.put(tick: System.os_time(:millisecond))

    {:noreply, socket}
  end
end
