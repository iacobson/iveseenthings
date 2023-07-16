defmodule IST.Systems.ReduceEvasion do
  @moduledoc """
  Every second, the evasion is reduced with 1.
  """

  use Ecspanse.System, lock_components: [IST.Components.Evasion]
  alias Ecspanse.Query

  @impl true
  def run(_frame) do
    Query.select({IST.Components.Evasion, IST.Components.EvasionTimer},
      with: [IST.Components.Defense]
    )
    |> Query.stream()
    |> Stream.map(fn {evasion, evasion_timer} ->
      new_value = ceil(evasion_timer.time / 1000)

      %{evasion: evasion, new_value: new_value}
    end)
    |> Stream.reject(fn %{evasion: evasion, new_value: new_value} ->
      evasion.value == new_value
    end)
    |> Enum.map(fn %{evasion: evasion, new_value: new_value} ->
      {evasion, value: new_value}
    end)
    |> Ecspanse.Command.update_components!()
  end
end
