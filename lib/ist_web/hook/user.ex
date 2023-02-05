defmodule ISTWeb.Hook.User do
  @moduledoc """
  The user hook module. Functions in this module are called by the router or liveview.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:user_status, _params, _session, socket) do
    # TODO: implement session and check if the user has a session
    # if the user has a session, find if it's already in a game
    # save the ECS token in a global prop

    with {:ok, socket} <- check_socket_connected(socket),
         {:ok, socket} <- fetch_token(socket),
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

  defp fetch_token(socket) do
    case Ecspanse.fetch_token(IST.Game) do
      {:ok, token} ->
        socket =
          socket
          |> assign(token: token)
          |> Surface.Components.Context.put(token: token)

        {:ok, socket}

      {:error, _} ->
        {:halt, socket}
    end
  end

  defp assign_user_id(socket) do
    {:ok, assign(socket, user_id: UUID.uuid4())}
  end
end
