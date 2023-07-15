defmodule ISTWeb.Components.BattleLog do
  @moduledoc """
  Battle log for player and target
  """
  use ISTWeb, :surface_live_component
  require Ex2ms

  alias Phoenix.LiveView.JS

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state

  prop player, :string, default: nil
  prop target, :string, default: nil
  prop select_player_event, :event

  data battle_log, :list, default: []

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> build_battle_log()

    {:ok, socket}
  end

  defp build_battle_log(socket) do
    player = socket.assigns.player
    target = socket.assigns.target

    {:ok, battle_logger_resource} =
      Ecspanse.Query.fetch_resource(IST.Resources.BattleLogger)

    table = battle_logger_resource.ecs_table

    f =
      if target do
        Ex2ms.fun do
          {{_system_time, hunter_id, target_id}, event}
          when hunter_id == ^player or
                 hunter_id == ^target or
                 target_id == ^player or
                 target_id == ^target ->
            {hunter_id, target_id, event}
        end
      else
        Ex2ms.fun do
          {{_system_time, hunter_id, target_id}, event}
          when hunter_id == ^player or
                 target_id == ^player ->
            {hunter_id, target_id, event}
        end
      end

    case :ets.select_reverse(table, f, 30) do
      {events, _} when is_list(events) ->
        log = compose_log(player, target, events, [])
        assign(socket, battle_log: log)

      events when is_list(events) ->
        log = compose_log(player, target, events, [])
        assign(socket, battle_log: log)

      _ ->
        socket
    end
  end

  defp compose_log(_player, _target, [], acc), do: Enum.reverse(acc)

  defp compose_log(player, target, [{hunter, prey, event} | events], acc) do
    log = %{
      hunter: %{name: name(player, target, hunter)},
      target: %{name: name(player, target, prey)},
      weapon: damage_type(event.damage_type),
      outcome: outcome(event),
      select: selection(player, target, hunter, prey)
    }

    compose_log(player, target, events, [log | acc])
  end

  defp selection(player, target, hunter, prey) do
    cond do
      player != hunter and target != hunter -> hunter
      player != prey and target != prey -> prey
      true -> nil
    end
  end

  defp name(player, target, id) do
    cond do
      player == id -> "You"
      target == id -> "Target"
      true -> String.slice(id, 0, 8)
    end
  end

  defp damage_type(damage) do
    case damage do
      :laser -> "[L]"
      :railgun -> "[R]"
      :missile -> "[M]"
    end
  end

  defp outcome(event) do
    case event.result do
      :miss ->
        %{result: :miss, text: "miss"}

      :stop ->
        %{result: :stop, text: "drone intercept"}

      :hit ->
        %{result: :hit, shields_damage: event.shields_damage, hull_damage: event.hull_damage}
    end
  end
end
