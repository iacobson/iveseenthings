defmodule IST.Systems.AddEnergy do
  @moduledoc """
  When the counter reaches zero, add energy to the ship and resets back the counter.
  """

  use Ecspanse.System, lock_components: [IST.Components.EnergyStorage]
  alias Ecspanse.Query

  alias IST.Events.EnergyTimerComplete

  @impl true
  def run(frame) do
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, frame) do
    events
    |> Stream.filter(fn
      %EnergyTimerComplete{} -> true
      _ -> false
    end)
    |> Enum.map(fn timer_event ->
      timer_event.entity
    end)
    |> update_energy(frame.token)
  end

  defp update_energy(entities, token) do
    # Careful with this situation!
    # if a list of entities would be empty, it would query for all entities!
    if Enum.any?(entities) do
      Query.select({IST.Components.EnergyStorage},
        with: [IST.Components.BattleShip],
        for: entities
      )
      |> Query.stream(token)
      |> Enum.map(fn {energy} ->
        {energy, value: energy.value + 1}
      end)
      |> Ecspanse.Command.update_components!()
    end
  end
end
