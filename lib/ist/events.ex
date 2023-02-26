defmodule IST.Events do
  @moduledoc """
  ECS events
  """

  defmodule AcquireTargetLock do
    @moduledoc """
    Acquires a target lock.
    Information about the target is available to the targeting user.
    The user can open fire on the target.
    """

    use Ecspanse.Event, fields: [:hunter_id, :target_id]

    @type t :: %__MODULE__{
            hunter_id: Ecspanse.Entity.id(),
            target_id: Ecspanse.Entity.id()
          }
  end

  defmodule PerformEvasiveManeuvers do
    @moduledoc """
    Performs an evasive maneuvers, if enough energy is available.
    Increases the ship's evasion.
    """

    use Ecspanse.Event, fields: [:ship_id]
  end

  defmodule BoostShields do
    @moduledoc """
    Boost energy shields, if enough energy is available.
    """

    use Ecspanse.Event, fields: [:ship_id]
  end

  defmodule SpawnDrone do
    @moduledoc """
    Spawns a new point defense drone.
    """

    use Ecspanse.Event, fields: [:ship_id]
  end

  defmodule FireWeapon do
    @moduledoc """
    Fires a weapon, if enough energy is available.
    The weapon should be one of :laser | :railgun | :missile

    The enemy fired upon should be the one in the ship's target lock.
    """

    use Ecspanse.Event, fields: [:weapon, :ship_id]
  end

  defmodule DealDamage do
    @moduledoc """
    Deals damage to a ship.


    Damage type can be :laser | :railgun | :missile
    """

    use Ecspanse.Event,
      fields: [
        :hunter_id,
        :target_id,
        :damage_type,
        :damage_value,
        :accuracy,
        :shields_efficiency
      ]
  end

  defmodule EnergyTimerComplete do
    @moduledoc """
    The energy timer has reached zero.
    """
    use Ecspanse.Event.Timer
  end

  defmodule EvasionTimerComplete do
    @moduledoc """
    Evasion reached zero.
    This is not really used.
    """
    use Ecspanse.Event.Timer
  end
end
