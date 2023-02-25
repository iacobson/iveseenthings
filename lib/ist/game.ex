defmodule IST.Game do
  @moduledoc """
  The Game world
  """

  use Ecspanse.World,
    otp_app: :iveseenthings,
    fps_limit: Application.compile_env(:iveseenthings, :fps_limit)

  alias Ecspanse.World

  def setup(world) do
    world
    |> World.add_system_set({__MODULE__, :startup_systems})
    |> World.add_system_set({__MODULE__, :sync_systems}, run_in_state: :play)
    |> World.add_system_set({__MODULE__, :async_event_systems}, run_in_state: :play)
    |> World.add_system_set({__MODULE__, :async_systems}, run_in_state: :play)
    |> World.add_frame_end_system(Ecspanse.System.Timer, run_in_state: :play)
    |> World.add_frame_end_system(IST.Systems.CheckPlayersConnected)
  end

  def startup_systems(world) do
    world
    |> World.add_startup_system(IST.Systems.InitGame)
  end

  def sync_systems(world) do
    world
    |> World.add_frame_start_system(IST.Systems.AddOrRemoveBots)
    |> World.add_frame_end_system(Ecspanse.System.TrackFPS)
    |> World.add_frame_end_system(IST.Systems.ResetCountdown)
    |> World.add_frame_end_system(IST.Systems.DestroyShip)
  end

  @doc "Systems triggered by user events"
  def async_event_systems(world) do
    world
    |> World.add_system(IST.Systems.TargetLock, after: [IST.Systems.CheckTargetAlive])
    |> World.add_system(IST.Systems.EvasiveManeuvers)
    |> World.add_system(IST.Systems.BoostShields)
    |> World.add_system(IST.Systems.SpawnDrone)
    |> World.add_system(IST.Systems.FireWeapon)
  end

  def async_systems(world) do
    world
    |> World.add_system(IST.Systems.CountingDown)
    |> World.add_system(IST.Systems.AddEnergy)
    |> World.add_system(IST.Systems.ReduceEvasion)
    |> World.add_system(IST.Systems.CheckTargetAlive)
    |> World.add_system(IST.Systems.BotAction)
    |> World.add_system(IST.Systems.DealDamage)
    |> World.add_system(IST.Systems.LevelUp)
  end
end
