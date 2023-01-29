defmodule IST.Game do
  @moduledoc """
  The Game world
  """

  use Ecspanse.World,
    otp_app: :iveseenthings,
    fps_limit: 60

  alias Ecspanse.World
  alias Ecspanse.Query

  def setup(world) do
    world
    |> World.add_startup_system(IST.Systems.InitBots)
    |> World.add_startup_system(IST.Systems.InitGame)
    |> World.add_frame_start_system(IST.Systems.FillBots, run_if: {__MODULE__, :needs_more_bots?})
  end

  def needs_more_bots?(token) do
    target_bot_count = Application.get_env(:iveseenthings, :bot_count)

    current_bot_count =
      Query.select({Ecspanse.Entity},
        with: [IST.Components.Bot]
      )
      |> Query.stream(token)
      |> Enum.count()

    target_bot_count > current_bot_count
  end
end
