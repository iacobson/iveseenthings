defmodule IST.Game do
  @moduledoc """
  The Game world
  """

  use Ecspanse.World,
    otp_app: :iveseenthings,
    fps_limit: 60

  alias Ecspanse.World

  def setup(world) do
    world
    |> World.add_startup_system(IST.Systems.InitGame)
    |> World.add_frame_start_system(IST.Systems.AddOrRemoveBots)
  end
end
