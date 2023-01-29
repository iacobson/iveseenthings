defmodule IST.Systems.InitGame do
  @moduledoc """
  Mark game ready to play
  """

  use Ecspanse.System

  @impl true
  def run(tick) do
    {:ok, world_state} = Ecspanse.Query.fetch_resource(Ecspanse.Resource.State, tick.token)
    Ecspanse.Command.update_resource!(world_state, %{value: :play})
  end
end
