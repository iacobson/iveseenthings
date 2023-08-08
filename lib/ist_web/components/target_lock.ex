defmodule ISTWeb.Components.TargetLock do
  @moduledoc """
  The targeted enemy.
  A player can only open fire upon targeted enemies.
  """
  use ISTWeb, :surface_live_component

  alias Ecspanse.Query
  alias Ecspanse.Entity
  alias IST.Components

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state

  @doc "The enemy target entity ID"
  prop targeted, :string, default: nil
  data enemy, :map, default: %{id: nil, name: nil, type: nil, energy: nil}

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> fetch_enemy()

    {:ok, socket}
  end

  defp fetch_enemy(socket) do
    with {:ok, entity} <- Entity.fetch(socket.assigns.targeted),
         {enemy_ship, energy, level} <-
           Query.select({Components.BattleShip, Components.EnergyStorage, Components.Level},
             for: [entity]
           )
           |> Query.one() do
      enemy =
        %{
          id: entity.id,
          name: String.slice(enemy_ship.name, 0, 13),
          energy: energy.value,
          level: level.value
        }
        |> add_type(entity)

      assign(socket, enemy: enemy)
    else
      _ ->
        socket
    end
  end

  defp add_type(enemy, entity) do
    if Query.has_component?(entity, Components.Human) do
      Map.put(enemy, :type, "human")
    else
      Map.put(enemy, :type, "bot")
    end
  end
end
