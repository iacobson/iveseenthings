defmodule IST.Systems.SpawnDroneTest do
  @moduledoc """
  Example of integration test using the IST.Debug genserver to manipulate the state.
  The disadvantage is that there is no guarantee for when the events will be executed,
  so the test needs to introduce some wait times.
  """
  use ExUnit.Case, async: false

  setup do
    # This is the real game world.
    {:ok, _pid} = start_supervised({IST.Game, :test})

    player_id = UUID.uuid4()
    ISTWeb.Presence.track(self(), "iveseenthings", player_id, %{})

    Ecspanse.event({IST.Events.AddPlayer, player_id: player_id}, batch_key: player_id)

    {:ok, _pid} = start_supervised(IST.Debug)

    :timer.sleep(100)
    {:ok, player_entity} = Ecspanse.Entity.fetch(player_id)

    {:ok, player_entity: player_entity}
  end

  test "adds a drone if enough energy", %{player_entity: player_entity} do
    # wait for the player to be created
    :timer.sleep(100)

    IST.Debug.add_energy(player_entity, 10)

    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(player_entity, IST.Components.EnergyStorage)

    energy_value = energy_component.value
    assert energy_value >= 6

    {drones_component} =
      Ecspanse.Query.select({IST.Components.Drones}, for_children_of: [player_entity])
      |> Ecspanse.Query.one()

    assert drones_component.count == 0

    Ecspanse.event(
      {IST.Events.SpawnDrone, ship_id: player_entity.id},
      batch_key: player_entity.id
    )

    # wait for the event to be processed
    :timer.sleep(100)

    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(player_entity, IST.Components.EnergyStorage)

    assert energy_component.value < energy_value

    {drones_component} =
      Ecspanse.Query.select({IST.Components.Drones}, for_children_of: [player_entity])
      |> Ecspanse.Query.one()

    assert drones_component.count == 1
  end

  test "does not add a drone if not enough energy", %{player_entity: player_entity} do
    # wait for the player to be created
    :timer.sleep(100)

    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(player_entity, IST.Components.EnergyStorage)

    energy_value = energy_component.value
    assert energy_value < 5

    {drones_component} =
      Ecspanse.Query.select({IST.Components.Drones}, for_children_of: [player_entity])
      |> Ecspanse.Query.one()

    assert drones_component.count == 0

    Ecspanse.event(
      {IST.Events.SpawnDrone, ship_id: player_entity.id},
      batch_key: player_entity.id
    )

    # wait for the event to be processed
    :timer.sleep(100)

    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(player_entity, IST.Components.EnergyStorage)

    assert energy_component.value >= energy_value

    {drones_component} =
      Ecspanse.Query.select({IST.Components.Drones}, for_children_of: [player_entity])
      |> Ecspanse.Query.one()

    assert drones_component.count == 0
  end
end
