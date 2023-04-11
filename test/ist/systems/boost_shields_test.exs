defmodule IST.Systems.BoostShieldsTest do
  @moduledoc """
  Example of unit test using Ecspanse.System.debug/1 to promote the test process to an Ecspanse System process.
  """
  use ExUnit.Case, async: false

  defmodule TestWorld do
    @moduledoc false
    use Ecspanse.World,
      otp_app: :iveseenthings

    @impl true
    def setup(world) do
      world
    end
  end

  setup do
    {:ok, token} = Ecspanse.new(TestWorld, name: TestWorld)
    player_id = UUID.uuid4()

    Ecspanse.System.debug(token)

    player_entity =
      Ecspanse.Command.spawn_entity!(
        {Ecspanse.Entity, name: player_id, components: [IST.Components.BattleShip]}
      )

    {:ok, token: token, player_entity: player_entity}
  end

  test "boost the shields if enough energy", %{token: token, player_entity: player_entity} do
    Ecspanse.Command.add_component!(player_entity, {IST.Components.EnergyStorage, value: 10})

    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(player_entity, IST.Components.EnergyStorage, token)

    assert energy_component.value == 10

    shields_entity =
      Ecspanse.Command.spawn_entity!(
        {Ecspanse.Entity,
         components: [
           IST.Components.Defense,
           {IST.Components.Shields, hp: 0, boost: 10},
           {IST.Components.EnergyCost, value: 4}
         ]}
      )

    Ecspanse.Command.add_child!(player_entity, shields_entity)

    event = %IST.Events.BoostShields{
      ship_id: player_entity.id,
      inserted_at: System.os_time()
    }

    frame = %Ecspanse.World.Frame{
      token: token,
      event_batches: [[event]],
      delta: 1
    }

    IST.Systems.BoostShields.run(event, frame)

    {:ok, energy_component} =
      Ecspanse.Query.fetch_component(player_entity, IST.Components.EnergyStorage, token)

    assert energy_component.value == 6

    {:ok, shields_component} =
      Ecspanse.Query.fetch_component(shields_entity, IST.Components.Shields, token)

    assert shields_component.hp == 10
  end
end
