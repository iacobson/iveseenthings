defmodule ISTWeb.Hook.User do
  @moduledoc """
  The user hook module. Functions in this module are called by the router or liveview.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:user_status, _params, _session, socket) do
    with {:ok, socket} <- check_socket_connected(socket),
         {:ok, socket} <- assign_user_id(socket) do
      {:cont, socket}
    end
  end

  defp check_socket_connected(socket) do
    if connected?(socket) do
      socket = assign(socket, socket_connected: true)
      {:ok, socket}
    else
      socket = assign(socket, socket_connected: false)
      {:cont, socket}
    end
  end

  defp assign_user_id(socket) do
    id = UUID.uuid4()

    socket =
      socket
      |> assign(user_id: id)
      |> Surface.Components.Context.put(user_id: id)

    {:ok, socket}
  end
end
