defmodule IST.Systems.UpdateFPS do
  @moduledoc """
  Updates the FPS resource
  """
  use Ecspanse.System

  @impl true
  def run(frame) do
    {:ok, fps_resource} = Ecspanse.Query.fetch_resource(IST.Resources.FPS, frame.token)
    fps = Float.round(1000 / frame.delta, 2)
    Ecspanse.Command.update_resource!(fps_resource, %{value: fps})
  end
end
