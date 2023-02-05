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
    Point defense drones. They are used to protect the ship from missiles and projectiles.
    By default, the drones offer a better protection against missiles than rasilguns.
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

  defmodule Missiles do
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

  defmodule Countdown do
    @moduledoc """
    Count down timer.
    Because an entity may need multiple countdowns, they will often be
    children entities.
    """
    use Ecspanse.Component, state: [millisecond: nil, initial: nil]

    @type t :: %__MODULE__{millisecond: non_neg_integer(), initial: non_neg_integer()}

    def validate(%__MODULE__{millisecond: millisecond, initial: initial}) do
      if is_integer(millisecond) and millisecond >= 0 and
           is_integer(initial) and initial >= 0 do
        :ok
      else
        {:error,
         "Count down value and the initial value must be a non negative integers. Got: #{inspect(millisecond)}, #{inspect(initial)}"}
      end
    end
  end

  defmodule EnergyCountdown do
    @moduledoc "Energy count down timer identifier"
    use Ecspanse.Component, access_mode: :entity_type
  end
end
