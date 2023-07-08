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
    Enum.each(frame.event_batches, fn events -> do_run(events, frame) end)
  end

  defp do_run(events, frame) do
    events =
      events
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
      {
        Ecspanse.Entity,
        IST.Components.EnergyStorage,
        Ecspanse.Component.Children
      },
      with: [IST.Components.BattleShip],
      for: entities
    )
    |> Query.stream(token)
    |> Stream.map(fn {ship_entity, energy, children} ->
      weapon_type = Enum.find(events, fn %{entity: entity} -> entity == ship_entity end).weapon
      weapon_module = Map.fetch!(@weapons, weapon_type)

      weapon_entity =
        children.entities
        |> Enum.find(fn entity ->
          Ecspanse.Query.is_type?(entity, weapon_module, token)
        end)

      {:ok, {energy_cost}} =
        Ecspanse.Query.fetch_components(
          weapon_entity,
          {IST.Components.EnergyCost},
          token
        )

      target_entity =
        children.entities
        |> Enum.find(fn entity ->
          Query.is_type?(entity, IST.Components.Target, token)
        end)

      %{
        ship_energy: energy,
        ship_entity: ship_entity,
        target_entity: target_entity,
        weapon_entity: weapon_entity,
        weapon_type: weapon_type,
        energy_cost: energy_cost
      }
    end)
    |> Stream.filter(fn %{
                          ship_energy: ship_energy,
                          energy_cost: energy_cost,
                          target_entity: target_entity
                        } ->
      ship_energy.value >= energy_cost.value && not is_nil(target_entity)
    end)
    |> Enum.map(fn %{
                     ship_energy: ship_energy,
                     ship_entity: ship_entity,
                     target_entity: target_entity,
                     weapon_entity: weapon_entity,
                     weapon_type: weapon_type,
                     energy_cost: energy_cost
                   } ->
      with {:ok, {damage, accuracy, efficiency}} <-
             Ecspanse.Query.fetch_components(
               weapon_entity,
               {IST.Components.Damage, IST.Components.Accuracy, IST.Components.ShieldsEfficiency},
               token
             ),
           {:ok, target_children} <-
             Query.fetch_component(target_entity, Ecspanse.Component.Children, token),
           # Alaways need to check if the target is still alive
           [target_ship_entity] <- target_children.entities do
        # Use the target as event key.
        # We want damage events for the same target to be processed in separate batches
        # to avoid race conditions
        Ecspanse.event(
          {
            IST.Events.DealDamage,
            hunter_id: ship_entity.id,
            target_id: target_ship_entity.id,
            damage_type: weapon_type,
            damage_value: damage.value,
            accuracy: accuracy.value,
            shields_efficiency: efficiency.percent
          },
          token,
          batch_key: target_ship_entity.id
        )

        update_ship_energy = {ship_energy, value: ship_energy.value - energy_cost.value}

        [update_ship_energy]
      else
        _ -> []
      end
    end)
    |> List.flatten()
    |> Ecspanse.Command.update_components!()
  end
end
