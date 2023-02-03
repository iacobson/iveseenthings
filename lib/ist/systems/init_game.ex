defmodule IST.Systems.InitGame do
  @moduledoc """
  Mark game ready to play
  """

  use Ecspanse.System

  @impl true
  def run(frame) do
    {:ok, world_state} = Ecspanse.Query.fetch_resource(Ecspanse.Resource.State, frame.token)
    Ecspanse.Command.update_resource!(world_state, %{value: :play})
    Ecspanse.Command.insert_resource!({IST.Resources.FPS, value: 0.0})
  end
end
