defmodule IST.Systems.InitBots do
  @moduledoc """
  When the game starts, create the bots.
  """

  use Ecspanse.System

  @impl true
  def run(_tick) do
    bot_count = Application.get_env(:iveseenthings, :bot_count)

    Ecspanse.System.execute_async(1..bot_count, fn _ ->
      IST.Systems.Helper.spawn_bot_entity()
    end)
  end
end
