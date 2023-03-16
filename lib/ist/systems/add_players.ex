defmodule IST.Systems.AddPlayers do
  @moduledoc """
  Add new players to the game.
  Allow extra 50 slots for human players.
  The bots will not refill unless under the number of configured :player_count.

  """

  use Ecspanse.System
  alias Ecspanse.Query
  alias IST.Events.AddPlayer, as: AddPlayerEvent

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  def do_run(events, frame) do
    events
    |> Enum.filter(fn
      %AddPlayerEvent{} ->
        true

      _ ->
        false
    end)
    |> Enum.each(fn %AddPlayerEvent{player_id: id} ->
      target_player_count = Application.get_env(:iveseenthings, :player_count)

      current_player_count =
        Query.select({Ecspanse.Entity},
          with: [IST.Components.BattleShip]
        )
        |> Query.stream(frame.token)
        |> Enum.count()

      if current_player_count < target_player_count + 50 do
        IST.Systems.Helper.spawn_human_entity(id)
      end
    end)
  end
end
