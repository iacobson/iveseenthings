defmodule IST.Systems.Helper do
  @moduledoc """
  Functions shared by more systems
  """

  alias IST.Components

  def spawn_bot_entity do
    name = UUID.uuid4()
    actor = Components.Bot
    do_spawn_battle_ship(actor, name)
  end

  def spawn_player_entity(name) do
    actor = Components.Player
    do_spawn_battle_ship(actor, name)
  end

  defp do_spawn_battle_ship(actor, name) do
    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       name: name,
       components: [
         {Components.BattleShip, name: name},
         actor,
         {Components.EnergyStorage, value: 1},
         {Components.Hull, hp: 100}
       ],
       children: [
         spawn_evasion_entity(),
         spawn_shields_entity(),
         spawn_drones_entity(),
         spawn_laser_entity(),
         spawn_railgun_entity(),
         spawn_missiles_entity()
       ]}
    )
  end

  # Defenses

  defp spawn_evasion_entity do
    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       components: [
         Components.Defense,
         {Components.Evasion, value: 30, maneuvers: 20},
         {Components.EnergyCost, value: 1}
       ]}
    )
  end

  defp spawn_shields_entity do
    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       components: [
         Components.Defense,
         {Components.Shields, hp: 10, boost: 15},
         {Components.EnergyCost, value: 4}
       ]}
    )
  end

  defp spawn_drones_entity do
    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       components: [
         Components.Defense,
         {Components.Drones, count: 0, missile_defense: 140, projectile_defense: 10, deploy: 1},
         {Components.EnergyCost, value: 6}
       ]}
    )
  end

  # Weapons

  defp spawn_laser_entity do
    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       components: [
         Components.Weapon,
         Components.Laser,
         {Components.Damage, value: 5},
         {Components.Accuracy, value: 100},
         {Components.ShieldsEfficiency, percent: 50},
         {Components.EnergyCost, value: 2}
       ]}
    )
  end

  defp spawn_railgun_entity do
    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       components: [
         Components.Weapon,
         Components.Railgun,
         {Components.Damage, value: 10},
         {Components.Accuracy, value: 30},
         {Components.ShieldsEfficiency, percent: 200},
         {Components.EnergyCost, value: 3}
       ]}
    )
  end

  defp spawn_missiles_entity do
    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       components: [
         Components.Weapon,
         Components.Missiles,
         {Components.Damage, value: 20},
         {Components.Accuracy, value: 70},
         {Components.ShieldsEfficiency, percent: 100},
         {Components.EnergyCost, value: 5}
       ]}
    )
  end
end
