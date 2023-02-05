defmodule ISTWeb.Presence do
  @moduledoc """
  Phoenix presence
  """
  use Phoenix.Presence,
    otp_app: :iveseenthings,
    pubsub_server: IST.PubSub
end
