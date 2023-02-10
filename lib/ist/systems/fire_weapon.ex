defmodule IST.Systems.FireWeapon do
  @moduledoc """
  Createas a damage event fot the locked target.
  The event is handled in the next frame
  Checks if the ship has enough energy to fire the weapon and consumes it.
  """

  use Ecspanse.System,
    lock_components: [
      IST.Components.EnergyStorage
    ]

  alias Ecspanse.Query
  alias IST.Events.FireWeapon, as: FireEvent

  @weapons %{
    laser: IST.Components.Laser,
    railgun: IST.Components.Railgun,
    missile: IST.Components.Missile
  }

  @impl true
  def run(frame) do
    events =
      frame.event_stream
      |> Stream.filter(fn
        %FireEvent{} -> true
        _ -> false
      end)
      |> Enum.map(fn %FireEvent{ship_id: id, weapon: weapon} ->
        %{entity: Ecspanse.Entity.build(id), weapon: weapon}
      end)

    if Enum.any?(events) do
      fire_weapon(events, frame.token)
    end
  end

  defp fire_weapon(events, token) do
    entities = Enum.map(events, fn %{entity: entity} -> entity end)

    Query.select(
      {Ecspanse.Entity, IST.Components.EnergyStorage, IST.Components.Target,
       Ecspanse.Component.Children},
      with: [IST.Components.BattleShip],
      for: entities
    )
    |> Query.stream(token)
    |> Stream.map(fn {ship_entity, energy, target, children} ->
      weapon_type = Enum.find(events, fn %{entity: entity} -> entity == ship_entity end).weapon
      weapon_module = Map.fetch!(@weapons, weapon_type)

      weapon_entity =
        children.list
        |> Enum.find(fn entity ->
          Ecspanse.Query.is_type?(entity, weapon_module, token)
        end)

      {:ok, {energy_cost}} =
        Ecspanse.Query.fetch_components(
          weapon_entity,
          {IST.Components.EnergyCost},
          token
        )

      %{
        ship_energy: energy,
        ship_entity: ship_entity,
        target: target,
        weapon_entity: weapon_entity,
        weapon_type: weapon_type,
        energy_cost: energy_cost
      }
    end)
    |> Stream.filter(fn %{
                          ship_energy: ship_energy,
                          energy_cost: energy_cost
                        } ->
      ship_energy.value >= energy_cost.value
    end)
    |> Enum.map(fn %{
                     ship_energy: ship_energy,
                     ship_entity: ship_entity,
                     target: target,
                     weapon_entity: weapon_entity,
                     weapon_type: weapon_type,
                     energy_cost: energy_cost
                   } ->
      {:ok, {damage, accuracy, efficiency}} =
        Ecspanse.Query.fetch_components(
          weapon_entity,
          {IST.Components.Damage, IST.Components.Accuracy, IST.Components.ShieldsEfficiency},
          token
        )

      # using random uuid as key
      # the issuer of the event is not important in this case
      Ecspanse.event(
        {
          IST.Events.DealDamage,
          UUID.uuid4(),
          hunter_id: ship_entity.id,
          target_id: target.entity.id,
          damage_type: weapon_type,
          damage_value: damage.value,
          accuracy: accuracy.value,
          shields_efficiency: efficiency.percent
        },
        token
      )

      update_ship_energy = {ship_energy, value: ship_energy.value - energy_cost.value}

      [update_ship_energy]
    end)
    |> List.flatten()
    |> Ecspanse.Command.update_components!()
  end
end
