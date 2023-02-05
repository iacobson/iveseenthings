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
    |> Stream.filter(fn {counter} -> counter.millisecond > 0 end)
    |> Enum.map(fn {counter} ->
      new_value = max(counter.millisecond - frame.delta, 0)
      {counter, %{millisecond: new_value}}
    end)
    |> Ecspanse.Command.update_components!()
  end
end
