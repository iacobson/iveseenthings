defmodule IST.Systems.ReduceEvasion do
  @moduledoc """
  Every second, the evasion is reduced with 1.
  """

  use Ecspanse.System, lock_components: [IST.Components.Evasion]
  alias Ecspanse.Query

  @impl true
  def run(frame) do
    Query.select({IST.Components.Evasion, Ecspanse.Component.Children},
      with: [IST.Components.Defense]
    )
    |> Query.stream(frame.token)
    |> Stream.map(fn {evasion, children} ->
      countdown_entity =
        children.list
        |> Enum.find(fn child ->
          Query.is_type?(child, IST.Components.EvasionCountdown, frame.token)
        end)

      {:ok, countdown_component} =
        Query.fetch_component(countdown_entity, IST.Components.Countdown, frame.token)

      new_value = ceil(countdown_component.millisecond / 1000)

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
