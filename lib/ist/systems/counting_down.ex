defmodule IST.Systems.CountingDown do
  @moduledoc """
  Counts down the time to the next action.
  """

  use Ecspanse.System, lock_components: [IST.Components.CountDown]
  alias Ecspanse.Query

  @impl true
  def run(frame) do
    Query.select({IST.Components.CountDown})
    |> Query.stream(frame.token)
    |> Ecspanse.System.execute_async(fn {counter} ->
      if counter.millisecond > 0 do
        new_value = max(counter.millisecond - frame.delta, 0)
        Ecspanse.Command.update_component!(counter, %{millisecond: new_value})
      end
    end)
  end
end
