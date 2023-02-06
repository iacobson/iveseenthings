defmodule IST.Util do
  @moduledoc """
  Utility functions
  """

  @doc """
  Retruns a key from a keyword list of odds.
  ## Example
    IST.UTIL.odds([stay: 50, go: 50])
    :stay
  """
  @spec odds(keyword()) :: atom()
  def odds(odds) do
    max_value = Keyword.values(odds) |> Enum.sum()
    random = :rand.uniform(max_value)
    return_key(odds, 0, random)
  end

  defp return_key([{key, value} | odds], acc, random) do
    if random <= acc + value do
      key
    else
      return_key(odds, acc + value, random)
    end
  end
end
