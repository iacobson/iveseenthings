defmodule IST.Game do
  @moduledoc """
  The Game world
  """

  use Ecspanse.World,
    otp_app: :iveseenthings,
    fps_limit: 60

  def setup(world) do
    world
  end
end
