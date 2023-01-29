defmodule IST.Components do
  @moduledoc """
  Ecspanse Components
  """

  defmodule BattleShip do
    @moduledoc "BattleShip identifier"
    use Ecspanse.Component, state: [name: nil], access_mode: :readonly
  end

  defmodule Bot do
    @moduledoc "BattleShip is a bot"
    use Ecspanse.Component, access_mode: :readonly
  end

  defmodule Player do
    @moduledoc "BattleShip is a player"
    use Ecspanse.Component, access_mode: :readonly
  end
end
