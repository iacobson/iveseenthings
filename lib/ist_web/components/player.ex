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

  prop(tick, :string, from_context: :tick)
  prop(state, :string, from_context: :state)

  @doc "The BattleShip entity ID"
  prop(selected, :string, default: nil)
  prop(target, :string, default: nil)

  data(player, :struct, default: %{id: nil})

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

  def handle_event(event, _params, socket) do
    player_id = socket.assigns.selected

    case event do
      "boost_shields" ->
        Ecspanse.event(
          {IST.Events.BoostShields, ship_id: player_id},
          batch_key: player_id
        )

      "maneuvers_evasion" ->
        Ecspanse.event(
          {IST.Events.PerformEvasiveManeuvers, ship_id: player_id},
          batch_key: player_id
        )

      "deploy_drones" ->
        Ecspanse.event({IST.Events.SpawnDrone, ship_id: player_id}, batch_key: player_id)

      "laser" ->
        Ecspanse.event(
          {IST.Events.FireWeapon, ship_id: player_id, weapon: :laser},
          batch_key: player_id
        )

      "railgun" ->
        Ecspanse.event(
          {IST.Events.FireWeapon, ship_id: player_id, weapon: :railgun},
          batch_key: player_id
        )

      "missile" ->
        Ecspanse.event(
          {IST.Events.FireWeapon, ship_id: player_id, weapon: :missile},
          batch_key: player_id
        )
    end

    {:noreply, socket}
  end

  defp fetch_player(socket) do
    case Entity.fetch(socket.assigns.selected) do
      {:ok, entity} ->
        player =
          if socket.assigns.selected && socket.assigns.player.id == socket.assigns.selected do
            # update just the dynamic values
            update_player(entity, socket.assigns.player)
          else
            # build the full player structure only when changing the selected player
            build_player(entity)
          end

        assign(socket, player: player)

      _ ->
        socket
    end
  end

  defp update_player(entity, player) do
    res =
      Query.select(
        {Components.EnergyStorage, Components.Hull, Components.Level,
         Ecspanse.Component.Children},
        for: [entity]
      )
      |> Query.one()

    case res do
      {energy, hull, level, children} ->
        children = children.entities

        %Player{
          player
          | energy: energy.value,
            hull: hull.hp,
            level: level.value,
            points: level.points,
            current_level_up_points: level.current_level_up_points,
            next_level_up_points: level.next_level_up_points
        }
        |> add_energy_countdown(entity)
        |> update_defenses(children)

      _ ->
        player
    end
  end

  defp update_defenses(player, children) do
    Query.select(
      {Entity, opt: Components.Evasion, opt: Components.Shields, opt: Components.Drones},
      with: [Components.Defense],
      for: children
    )
    |> Query.stream()
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

  defp build_player(entity) do
    {player, energy, hull, level, children} =
      Query.select(
        {Components.BattleShip, Components.EnergyStorage, Components.Hull, Components.Level,
         Ecspanse.Component.Children},
        for: [entity]
      )
      |> Query.one()

    children = children.entities

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
    |> add_type(entity)
    |> add_energy_countdown(entity)
    |> add_evasion(children)
    |> add_shields(children)
    |> add_drones(children)
    |> add_laser(children)
    |> add_railgun(children)
    |> add_missile(children)
  end

  defp add_type(player, entity) do
    if Query.has_component?(entity, Components.Human) do
      Map.put(player, :type, "human")
    else
      Map.put(player, :type, "bot")
    end
  end

  def add_energy_countdown(player, entity) do
    {:ok, energy_timer} = Query.fetch_component(entity, Components.EnergyTimer)
    Map.put(player, :energy_countdown, energy_timer.time)
  end

  defp add_evasion(player, children) do
    {evasion, cost} =
      Query.select(
        {Components.Evasion, Components.EnergyCost},
        with: [Components.Defense],
        for: children
      )
      |> Query.one()

    Map.merge(player, %{
      current_evasion: evasion.value,
      maneuvers_evasion: evasion.maneuvers,
      maneuvers_evasion_energy_cost: cost.value
    })
  end

  defp add_shields(player, children) do
    {shields, cost} =
      Query.select(
        {Components.Shields, Components.EnergyCost},
        with: [Components.Defense],
        for: children
      )
      |> Query.one()

    Map.merge(player, %{
      current_shields: shields.hp,
      boost_shields: shields.boost,
      boost_shields_energy_cost: cost.value
    })
  end

  defp add_drones(player, children) do
    {drones, cost} =
      Query.select(
        {Components.Drones, Components.EnergyCost},
        with: [Components.Defense],
        for: children
      )
      |> Query.one()

    Map.merge(player, %{
      current_drones: drones.count,
      deploy_drones: drones.deploy,
      deploy_drones_energy_cost: cost.value,
      drones_missile_defense: drones.missile_defense,
      drones_projectile_defense: drones.projectile_defense
    })
  end

  defp add_laser(player, children) do
    {damage, accuracy, efficiency, cost} =
      Query.select(
        {Components.Damage, Components.Accuracy, Components.ShieldsEfficiency,
         Components.EnergyCost},
        with: [Components.Weapon, Components.Laser],
        for: children
      )
      |> Query.one()

    Map.merge(player, %{
      laser_damage: damage.value,
      laser_accuracy: accuracy.value,
      laser_energy_cost: cost.value,
      laser_shields_efficiency: efficiency.percent
    })
  end

  defp add_railgun(player, children) do
    {damage, accuracy, efficiency, cost} =
      Query.select(
        {Components.Damage, Components.Accuracy, Components.ShieldsEfficiency,
         Components.EnergyCost},
        with: [Components.Weapon, Components.Railgun],
        for: children
      )
      |> Query.one()

    Map.merge(player, %{
      railgun_damage: damage.value,
      railgun_accuracy: accuracy.value,
      railgun_energy_cost: cost.value,
      railgun_shields_efficiency: efficiency.percent
    })
  end

  defp add_missile(player, children) do
    {damage, accuracy, efficiency, cost} =
      Query.select(
        {Components.Damage, Components.Accuracy, Components.ShieldsEfficiency,
         Components.EnergyCost},
        with: [Components.Weapon, Components.Missile],
        for: children
      )
      |> Query.one()

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
