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

  @doc "Calculate the Fibonacci sequence result for a specific level, startig with the base"
  @spec fibo_calculate(base :: non_neg_integer(), level :: pos_integer()) ::
          current :: non_neg_integer()
  def fibo_calculate(base, 1), do: base

  def fibo_calculate(base, level) do
    do_calculate_fibo(base, base, 1, level)
  end

  defp do_calculate_fibo(current, _prev, target, target), do: current

  defp do_calculate_fibo(current, prev, count, target) do
    do_calculate_fibo(current + prev, current, count + 1, target)
  end
end
