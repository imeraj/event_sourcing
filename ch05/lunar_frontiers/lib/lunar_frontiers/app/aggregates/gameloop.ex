defmodule LunarFrontiers.App.Aggregates.Gameloop do
  @moduledoc false

  alias LunarFrontiers.App.Events.GameloopAdvanced
  alias LunarFrontiers.App.Commands.AdvanceGameloop
  alias __MODULE__

  defstruct [:game_id, :tick]

  # Command Handlers
  def execute(%Gameloop{} = _loop, %AdvanceGameloop{} = advance_loop) do
    %{game_id: id, tick: tick} = advance_loop

    event = %GameloopAdvanced{game_id: id, tick: tick}

    {:ok, event}
  end

  # State Mutators
  def apply(%Gameloop{} = loop, %GameloopAdvanced{} = advance_loop) do
    %{game_id: id, tick: tick} = advance_loop

    %Gameloop{
      game_id: id,
      tick: tick
    }
  end
end
