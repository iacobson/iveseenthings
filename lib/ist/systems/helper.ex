defmodule IST.Systems.Helper do
  @moduledoc """
  Functions shared by more systems
  """

  def spawn_bot_entity do
    name = UUID.uuid4()

    Ecspanse.Command.spawn_entity!(
      {Ecspanse.Entity,
       name: name,
       components: [
         {IST.Components.BattleShip, name: name},
         IST.Components.Bot
       ]}
    )
  end
end
