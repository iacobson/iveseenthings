defmodule IST.Game do
  @moduledoc """
  The Game scheduler
  """

  use Ecspanse,
    fps_limit: Application.compile_env(:iveseenthings, :fps_limit)

  @impl Ecspanse
  def setup(data) do
    data
    |> Ecspanse.add_system_set({__MODULE__, :startup_systems})
    |> Ecspanse.add_system_set({__MODULE__, :sync_systems}, run_in_state: :play)
    |> Ecspanse.add_system_set({__MODULE__, :async_event_systems}, run_in_state: :play)
    |> Ecspanse.add_system_set({__MODULE__, :async_systems}, run_in_state: :play)
    |> Ecspanse.add_frame_end_system(Ecspanse.System.Timer, run_in_state: :play)
    |> Ecspanse.add_frame_end_system(IST.Systems.CheckPlayersConnected)
  end

  def startup_systems(data) do
    data
    |> Ecspanse.add_startup_system(IST.Systems.InitGame)
  end

  def sync_systems(data) do
    data
    |> Ecspanse.add_frame_start_system(IST.Systems.AddPlayers)
    |> Ecspanse.add_frame_start_system(IST.Systems.AddOrRemoveBots)
    |> Ecspanse.add_frame_end_system(Ecspanse.System.TrackFPS)
    |> Ecspanse.add_frame_end_system(IST.Systems.DestroyShip)
  end

  @doc "Systems triggered by user events"
  def async_event_systems(data) do
    data
    |> Ecspanse.add_system(IST.Systems.TargetLock, after: [IST.Systems.CheckTargetAlive])
    |> Ecspanse.add_system(IST.Systems.EvasiveManeuvers)
    |> Ecspanse.add_system(IST.Systems.BoostShields)
    |> Ecspanse.add_system(IST.Systems.SpawnDrone)
    |> Ecspanse.add_system(IST.Systems.FireWeapon)
  end

  def async_systems(data) do
    data
    |> Ecspanse.add_system(IST.Systems.AddEnergy)
    |> Ecspanse.add_system(IST.Systems.ReduceEvasion)
    |> Ecspanse.add_system(IST.Systems.CheckTargetAlive)
    |> Ecspanse.add_system(IST.Systems.BotAction)
    |> Ecspanse.add_system(IST.Systems.DealDamage)
    |> Ecspanse.add_system(IST.Systems.LevelUp)
    |> Ecspanse.add_system(IST.Systems.CleanLogger)
  end
end
