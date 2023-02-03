defmodule IST.Resources do
  @moduledoc """
  ECSpanse Resources
  """

  defmodule FPS do
    @moduledoc "Keeps track of the FPS"

    use Ecspanse.Resource, state: [value: nil]
  end
end
