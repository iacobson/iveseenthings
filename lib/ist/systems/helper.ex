defmodule IST.Systems.Helper do
  @moduledoc """
  Functions shared by more systems
  """

  alias IST.Components

  def spawn_bot_entity do
    name = UUID.uuid4()
    player = Components.Bot
    do_spawn_battle_ship(player, name)
  end

  def spawn_human_entity(name) do
    player = Components.Human
    do_spawn_battle_ship(player, name)
  end

  defp do_spawn_battle_ship(player, name) do
    children =
      Ecspanse.Command.spawn_entities!([
        evasion_entity_spec(),
        shields_entity_spec(),
        drones_entity_spec(),
        laser_entity_spec(),
        railgun_entity_spec(),
        missile_entity_spec()
      ])

    Ecspanse.Command.spawn_entities!([
      {Ecspanse.Entity,
       id: name,
       components: [
         Components.EnergyTimer,
         {Components.BattleShip, name: name},
         player,
         {Components.EnergyStorage, value: 1},
         {Components.Hull, hp: 100},
         {Components.Level, points: 0, value: 1, next_level_up_points: 100}
       ],
       children: children}
    ])
  end

  # Defenses

  defp evasion_entity_spec do
    {Ecspanse.Entity,
     components: [
       Components.Defense,
       Components.EvasionTimer,
       {Components.Evasion, value: 0, maneuvers: 10},
       {Components.EnergyCost, value: 1}
     ]}
  end

  defp shields_entity_spec do
    {Ecspanse.Entity,
     components: [
       Components.Defense,
       {Components.Shields, hp: 10, boost: 15},
       {Components.EnergyCost, value: 4}
     ]}
  end

  defp drones_entity_spec do
    {Ecspanse.Entity,
     components: [
       Components.Defense,
       {Components.Drones, count: 0, missile_defense: 140, projectile_defense: 10, deploy: 1},
       {Components.EnergyCost, value: 6}
     ]}
  end

  # Weapons

  defp laser_entity_spec do
    {Ecspanse.Entity,
     components: [
       Components.Weapon,
       Components.Laser,
       {Components.Damage, value: 5},
       {Components.Accuracy, value: 100},
       {Components.ShieldsEfficiency, percent: 50},
       {Components.EnergyCost, value: 2}
     ]}
  end

  defp railgun_entity_spec do
    {Ecspanse.Entity,
     components: [
       Components.Weapon,
       Components.Railgun,
       {Components.Damage, value: 10},
       {Components.Accuracy, value: 30},
       {Components.ShieldsEfficiency, percent: 200},
       {Components.EnergyCost, value: 3}
     ]}
  end

  defp missile_entity_spec do
    {Ecspanse.Entity,
     components: [
       Components.Weapon,
       Components.Missile,
       {Components.Damage, value: 20},
       {Components.Accuracy, value: 70},
       {Components.ShieldsEfficiency, percent: 100},
       {Components.EnergyCost, value: 5}
     ]}
  end
end
