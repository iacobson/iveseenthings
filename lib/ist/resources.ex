defmodule IST.Resources do
  @moduledoc """
  ECSpanse Resources
  """

  defmodule BattleLogger do
    @moduledoc """
    Holds the name of the ETS table that keeps the battle log.
    The log is in this format:
    {
      {
        1675092999535[System time],
        "hunter_id",
        "target_id
      },
      %{
        result: :hit | :miss | :stop,
        damage_type: :laser | :railgun | :missile,
        shields_damage: 10,
        hull_damage: 5
      }
    }
    """
    use Ecspanse.Resource, state: [ecs_table: nil]

    @type t :: %__MODULE__{ecs_table: binary()}
  end
end
