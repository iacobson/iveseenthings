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
    Performs an evasive maneuvers.
    Increases the ship's evasion.
    """

    use Ecspanse.Event, fields: [:ship_id]
  end
end
