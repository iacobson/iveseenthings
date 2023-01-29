defmodule ISTWeb.Live.Game do
  @moduledoc """
  The main game live view.
  """

  use ISTWeb, :surface_live_view
  prop socket_connected, :boolean, default: false
end
