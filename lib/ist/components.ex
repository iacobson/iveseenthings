defmodule IST.Components do
  @moduledoc """
  Ecspanse Components
  """

  # Ship

  defmodule BattleShip do
    @moduledoc "BattleShip identifier"
    use Ecspanse.Component, state: [name: nil], access_mode: :readonly
  end

  defmodule Bot do
    @moduledoc "BattleShip is a bot"
    use Ecspanse.Component, access_mode: :entity_type
  end

  defmodule Human do
    @moduledoc "BattleShip is a human"
    use Ecspanse.Component, access_mode: :entity_type
  end

  defmodule Hull do
    @moduledoc "BattleShip Hull. If the hull reaches hp 0, the ship is destroyed."
    use Ecspanse.Component, state: [hp: nil]

    @type t :: %__MODULE__{hp: non_neg_integer()}

    def validate(%__MODULE__{hp: hp}) do
      if is_integer(hp) do
        :ok
      else
        {:error, "Hull hp must be an integer. Got: #{inspect(hp)}"}
      end
    end
  end

  defmodule EnergyStorage do
    @moduledoc """
    Energy is the main resource of the ship. All the actions require some amount energy.
    The energy is restored by one point every 3 seconds.
    The player should not get new energy points when not in a combat (is alone in the location),
    or when in the shop between locations.
    """

    use Ecspanse.Component, state: [value: nil]

    @type t :: %__MODULE__{value: non_neg_integer()}

    def validate(%__MODULE__{value: value}) do
      if is_integer(value) and value >= 0 do
        :ok
      else
        {:error, "Energy value must be a non negative integer. Got: #{inspect(value)}"}
      end
    end
  end

  defmodule EnergyCost do
    @moduledoc "Weapon Energy Cost"
    use Ecspanse.Component, state: [value: nil]

    @type t :: %__MODULE__{value: non_neg_integer()}

    def validate(%__MODULE__{value: value}) do
      if is_integer(value) and value >= 0 do
        :ok
      else
        {:error, "Energy cost value must be a non negative integer. Got: #{inspect(value)}"}
      end
    end
  end

  defmodule Target do
    @moduledoc """
    The entity of this type is storing the targeted enemy as child.
    That means that the targeted enemy can check all the Target type parents to find the entity that is targeting it.

    Attention: The logic relays on the fact the the entity of type Target has a single child (a BattleShip), and a single parent (a BattleShip).
    If the entity type Target has no child, it should be despawned. So when a BattleShip has a Target type child, it guarantees the
    child of the Target type is a BattleShip.

    """

    use Ecspanse.Component, access_mode: :entity_type
  end

  defmodule Level do
    @moduledoc """
    The player levels up while accumulating points.
    The base is the base for Fibo calculation of level-up
    """

    use Ecspanse.Component,
      state: [
        value: nil,
        points: 0,
        current_level_up_points: 0,
        next_level_up_points: 100,
        base: 100
      ]

    @type t :: %__MODULE__{
            value: pos_integer(),
            points: non_neg_integer(),
            current_level_up_points: pos_integer(),
            next_level_up_points: pos_integer(),
            base: pos_integer()
          }

    def validate(%__MODULE__{value: value, points: points}) do
      if is_integer(value) and value >= 1 && points >= 0 do
        :ok
      else
        {:error, "Level must be a positive integer. And points must be non-negative.}"}
      end
    end
  end

  # Defenses

  defmodule Defense do
    @moduledoc "Defense identifier"
    use Ecspanse.Component, access_mode: :readonly
  end

  defmodule Evasion do
    @moduledoc """
    BattleShip Evasion. Balances the weapon's accuracy.
    The highest the evasion, the higher the chance of the emey to miss the attack.
    The evasion decreases every second.
    But it can be restored with the Evasive Maneuvers action.
    """
    use Ecspanse.Component, state: [value: nil, maneuvers: nil]

    @type t :: %__MODULE__{value: non_neg_integer(), maneuvers: non_neg_integer()}

    def validate(%__MODULE__{value: value, maneuvers: maneuvers}) do
      if is_integer(value) and value >= 0 and
           is_integer(maneuvers) and maneuvers >= 0 do
        :ok
      else
        {:error,
         "Evasion and maneuvers values must be  non negative integer. Got: #{inspect(value)}, #{inspect(maneuvers)}"}
      end
    end
  end

  defmodule Shields do
    @moduledoc """
    The shields absorbs damage form the enemy attacks.
    The shields are more effective against lasers, while quite vulnerable to the railguns.
    The weapon's shields efficiency attribute is used to calculate the damage absorbed by the shields.
    The shields can be restored with the Shield Boost action.
    """

    use Ecspanse.Component, state: [hp: nil, boost: nil]

    @type t :: %__MODULE__{hp: non_neg_integer(), boost: non_neg_integer()}

    def validate(%__MODULE__{hp: hp, boost: boost}) do
      if is_integer(hp) and hp >= 0 and
           is_integer(boost) and boost >= 0 do
        :ok
      else
        {:error,
         "Shields hp and boost must be  non negative integer. Got: #{inspect(hp)}, #{inspect(boost)}"}
      end
    end
  end

  defmodule Drones do
    @moduledoc """
    Point defense drones. They are used to protect the ship from missile and projectiles.
    By default, the drones offer a better protection against missile than rasilguns.
    More drones can be deployed in the same time with the Drone Deploy action.
    If the hull takes any damage from one shot, one drone is destroyed.
    The drone defense is compared with the weapon's accuracy.
    """

    use Ecspanse.Component,
      state: [count: nil, missile_defense: nil, projectile_defense: nil, deploy: nil]

    @type t :: %__MODULE__{
            count: non_neg_integer(),
            missile_defense: non_neg_integer(),
            projectile_defense: non_neg_integer(),
            deploy: non_neg_integer()
          }

    def validate(%__MODULE__{
          count: count,
          missile_defense: missile_defense,
          projectile_defense: projectile_defense,
          deploy: deploy
        }) do
      if is_integer(count) and count >= 0 and
           is_integer(missile_defense) and missile_defense >= 0 and
           is_integer(projectile_defense) and projectile_defense >= 0 and
           is_integer(deploy) and deploy >= 0 do
        :ok
      else
        {:error,
         "Drones count, missile_defense and projectile_defense must be non negative integers. Got: #{inspect(count)}, #{inspect(missile_defense)}, #{inspect(projectile_defense)}"}
      end
    end
  end

  # Weapons

  defmodule Weapon do
    @moduledoc "Weapon identifier"
    use Ecspanse.Component, access_mode: :readonly
  end

  defmodule Laser do
    @moduledoc "Laser weapon"
    use Ecspanse.Component, access_mode: :entity_type
  end

  defmodule Railgun do
    @moduledoc "Railgun weapon"
    use Ecspanse.Component, access_mode: :entity_type
  end

  defmodule Missile do
    @moduledoc "Missile weapon"
    use Ecspanse.Component, access_mode: :entity_type
  end

  defmodule Damage do
    @moduledoc "Weapon Damage per shot"
    use Ecspanse.Component, state: [value: nil]

    @type t :: %__MODULE__{value: non_neg_integer()}

    def validate(%__MODULE__{value: value}) do
      if is_integer(value) and value >= 0 do
        :ok
      else
        {:error, "Damage value must be a non negative integer. Got: #{inspect(value)}"}
      end
    end
  end

  defmodule Accuracy do
    @moduledoc "Weapon Accuracy"
    use Ecspanse.Component, state: [value: nil]

    @type t :: %__MODULE__{value: non_neg_integer()}

    def validate(%__MODULE__{value: value}) do
      if is_integer(value) and value >= 0 do
        :ok
      else
        {:error, "Accuracy value must be a non negative integer. Got: #{inspect(value)}"}
      end
    end
  end

  defmodule ShieldsEfficiency do
    @moduledoc "Weapon Shield Efficiency"
    use Ecspanse.Component, state: [percent: nil]

    @type t :: %__MODULE__{percent: non_neg_integer()}

    def validate(%__MODULE__{percent: percent}) do
      if is_integer(percent) and percent >= 0 do
        :ok
      else
        {:error,
         "Shield efficiency value must be a non negative integer. Got: #{inspect(percent)}"}
      end
    end
  end

  # Generic

  defmodule EnergyTimer do
    @moduledoc "Energy Timer component"
    use Ecspanse.Component.Timer,
      state: [duration: 3000, event: IST.Events.EnergyTimerComplete, mode: :repeat]
  end

  defmodule EvasionTimer do
    @moduledoc """
    The eveasion timer keeps track of the actual evasion value.
    """

    use Ecspanse.Component.Timer,
      state: [duration: 30 * 1000, event: IST.Events.EvasionTimerComplete, mode: :once]
  end
end
