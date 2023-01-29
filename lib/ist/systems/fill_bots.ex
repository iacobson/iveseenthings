defmodule IST.Systems.FillBots do
  @moduledoc """
  Fill the target number of bots.
  Eg. If the bots were destroyed, this will spawn new ones.
  """

  use Ecspanse.System
  alias Ecspanse.Query

  @impl true
  def run(tick) do
    target_bot_count = Application.get_env(:iveseenthings, :bot_count)

    current_bot_count =
      Query.select({Ecspanse.Entity},
        with: [IST.Components.Bot]
      )
      |> Query.stream(tick.token)
      |> Enum.count()

    bot_count = target_bot_count - current_bot_count

    if bot_count > 0 do
      Ecspanse.System.execute_async(1..bot_count, fn _ ->
        IST.Systems.Helper.spawn_bot_entity()
      end)
    end

    IO.inspect(tick.delta)
  end
end
