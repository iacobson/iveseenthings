defmodule ISTWeb.Components.Player do
  @moduledoc """
  The Player
  Depending on the game state:
  - :observer -> the selected player
  - :play -> THE player
  """
  use ISTWeb, :surface_live_component

  alias __MODULE__
  alias Ecspanse.Query
  alias Ecspanse.Entity
  alias IST.Components

  prop tick, :string, from_context: :tick
  prop state, :string, from_context: :state
  prop token, :string, from_context: :token

  @doc "The BattleShip entity ID"
  prop selected, :string, default: nil
  data player, :struct, default: %{id: nil}

  defstruct id: nil,
            name: nil,
            type: nil,
            energy: nil,
            energy_countdown: nil,
            hull: nil,
            points: nil,
            level: nil,
            current_level_up_points: nil,
            next_level_up_points: nil,
            current_evasion: nil,
            maneuvers_evasion: nil,
            maneuvers_evasion_energy_cost: nil,
            current_shields: nil,
            boost_shields: nil,
            boost_shields_energy_cost: nil,
            current_drones: nil,
            deploy_drones: nil,
            deploy_drones_energy_cost: nil,
            drones_missile_defense: nil,
            drones_projectile_defense: nil,
            laser_damage: nil,
            laser_accuracy: nil,
            laser_energy_cost: nil,
            laser_shields_efficiency: nil,
            railgun_damage: nil,
            railgun_accuracy: nil,
            railgun_energy_cost: nil,
            railgun_shields_efficiency: nil,
            missile_damage: nil,
            missile_accuracy: nil,
            missile_energy_cost: nil,
            missile_shields_efficiency: nil

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> fetch_player()

    {:ok, socket}
  end

  defp fetch_player(socket) do
    entity = Entity.build(socket.assigns.selected)

    player =
      if socket.assigns.selected && socket.assigns.player.id == socket.assigns.selected do
        # update just the dynamic values
        update_player(entity, socket.assigns.player, socket.assigns.token)
      else
        # build the full player structure only when changing the selected player
        build_player(entity, socket.assigns.token)
      end

    assign(socket, player: player)
  end

  defp update_player(entity, player, token) do
    res =
      Query.select(
        {Components.EnergyStorage, Components.Hull, Components.Level,
         Ecspanse.Component.Children},
        for: [entity]
      )
      |> Query.one(token)

    case res do
      {energy, hull, level, children} ->
        children = children.list

        %Player{
          player
          | energy: energy.value,
            hull: hull.hp,
            level: level.value,
            points: level.points,
            current_level_up_points: level.current_level_up_points,
            next_level_up_points: level.next_level_up_points
        }
        |> add_energy_countdown(entity, token)
        |> update_defenses(children, token)

      _ ->
        player
    end
  end

  defp update_defenses(player, children, token) do
    Query.select(
      {Entity, opt: Components.Evasion, opt: Components.Shields, opt: Components.Drones},
      with: [Components.Defense],
      for: children
    )
    |> Query.stream(token)
    |> Enum.reduce(player, fn
      {_entity, %Components.Evasion{value: evasion}, _, _}, player ->
        %Player{player | current_evasion: evasion}

      {_entity, _, %Components.Shields{hp: shields}, _}, player ->
        %Player{player | current_shields: shields}

      {_entity, _, _, %Components.Drones{count: drones}}, player ->
        %Player{player | current_drones: drones}

      _, player ->
        player
    end)
  end

  defp build_player(entity, token) do
    {player, energy, hull, level, children} =
      Query.select(
        {Components.BattleShip, Components.EnergyStorage, Components.Hull, Components.Level,
         Ecspanse.Component.Children},
        for: [entity]
      )
      |> Query.one(token)

    children = children.list

    %Player{
      id: entity.id,
      name: String.slice(player.name, 0, 13),
      energy: energy.value,
      hull: hull.hp,
      level: level.value,
      points: level.points,
      current_level_up_points: level.current_level_up_points,
      next_level_up_points: level.next_level_up_points
    }
    |> add_type(entity, token)
    |> add_energy_countdown(entity, token)
    |> add_evasion(children, token)
    |> add_shields(children, token)
    |> add_drones(children, token)
    |> add_laser(children, token)
    |> add_railgun(children, token)
    |> add_missile(children, token)
  end

  defp add_type(player, entity, token) do
    if Query.has_component?(entity, Components.Human, token) do
      Map.put(player, :type, "human")
    else
      Map.put(player, :type, "bot")
    end
  end

  def add_energy_countdown(player, entity, token) do
    {:ok, energy_timer} = Query.fetch_component(entity, Components.EnergyTimer, token)
    Map.put(player, :energy_countdown, energy_timer.time)
  end

  defp add_evasion(player, children, token) do
    {evasion, cost} =
      Query.select(
        {Components.Evasion, Components.EnergyCost},
        with: [Components.Defense],
        for: children
      )
      |> Query.one(token)

    Map.merge(player, %{
      current_evasion: evasion.value,
      maneuvers_evasion: evasion.maneuvers,
      maneuvers_energy_cost: cost.value
    })
  end

  defp add_shields(player, children, token) do
    {shields, cost} =
      Query.select(
        {Components.Shields, Components.EnergyCost},
        with: [Components.Defense],
        for: children
      )
      |> Query.one(token)

    Map.merge(player, %{
      current_shields: shields.hp,
      boost_shields: shields.boost,
      boost_shields_energy_cost: cost.value
    })
  end

  defp add_drones(player, children, token) do
    {drones, cost} =
      Query.select(
        {Components.Drones, Components.EnergyCost},
        with: [Components.Defense],
        for: children
      )
      |> Query.one(token)

    Map.merge(player, %{
      current_drones: drones.count,
      deploy_drones: drones.deploy,
      deploy_drones_energy_cost: cost.value,
      drones_missile_defense: drones.missile_defense,
      drones_projectile_defense: drones.projectile_defense
    })
  end

  defp add_laser(player, children, token) do
    {damage, accuracy, efficiency, cost} =
      Query.select(
        {Components.Damage, Components.Accuracy, Components.ShieldsEfficiency,
         Components.EnergyCost},
        with: [Components.Weapon, Components.Laser],
        for: children
      )
      |> Query.one(token)

    Map.merge(player, %{
      laser_damage: damage.value,
      laser_accuracy: accuracy.value,
      laser_energy_cost: cost.value,
      laser_shields_efficiency: efficiency.percent
    })
  end

  defp add_railgun(player, children, token) do
    {damage, accuracy, efficiency, cost} =
      Query.select(
        {Components.Damage, Components.Accuracy, Components.ShieldsEfficiency,
         Components.EnergyCost},
        with: [Components.Weapon, Components.Railgun],
        for: children
      )
      |> Query.one(token)

    Map.merge(player, %{
      railgun_damage: damage.value,
      railgun_accuracy: accuracy.value,
      railgun_energy_cost: cost.value,
      railgun_shields_efficiency: efficiency.percent
    })
  end

  defp add_missile(player, children, token) do
    {damage, accuracy, efficiency, cost} =
      Query.select(
        {Components.Damage, Components.Accuracy, Components.ShieldsEfficiency,
         Components.EnergyCost},
        with: [Components.Weapon, Components.Missile],
        for: children
      )
      |> Query.one(token)

    Map.merge(player, %{
      missile_damage: damage.value,
      missile_accuracy: accuracy.value,
      missile_energy_cost: cost.value,
      missile_shields_efficiency: efficiency.percent
    })
  end

  ### template helpers

  defp energy_progress(counter) do
    counter = ceil(counter / 1000)
    counter = 4 - counter
    String.slice("❚❚❚", 0, counter)
  end
end
