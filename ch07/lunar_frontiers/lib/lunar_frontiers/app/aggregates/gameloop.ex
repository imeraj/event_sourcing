defmodule LunarFrontiers.App.Aggregates.Gameloop do
  @moduledoc false

  alias LunarFrontiers.App.Events.GameloopAdvanced
  alias LunarFrontiers.App.Events.GameStarted
  alias LunarFrontiers.App.Events.GameStopped
  alias LunarFrontiers.App.Commands.StartGame
  alias LunarFrontiers.App.Commands.StopGame
  alias LunarFrontiers.App.Commands.AdvanceGameloop

  alias __MODULE__

  defstruct [:game_id, :tick]

  # Command Handlers
  def execute(%Gameloop{} = _loop, %StartGame{game_id: gid}) do
    event = %GameStarted{game_id: gid}

    {:ok, event}
  end

  def execute(%Gameloop{} = _loop, %AdvanceGameloop{} = advance_loop) do
    %{game_id: id, tick: tick} = advance_loop

    event = %GameloopAdvanced{game_id: id, tick: tick}

    {:ok, event}
  end

  def execute(%Gameloop{} = _loop, %StopGame{game_id: gid}) do
    event = %GameStopped{game_id: gid}

    {:ok, event}
  end

  # State Mutators
  def apply(
        %Gameloop{} = _loop,
        %GameStarted{game_id: gid}
      ) do
    %Gameloop{
      game_id: gid,
      tick: 0
    }
  end

  def apply(%Gameloop{} = _loop, %GameloopAdvanced{} = advance_loop) do
    %{game_id: id, tick: tick} = advance_loop

    %Gameloop{
      game_id: id,
      tick: tick
    }
  end

  def apply(
        %Gameloop{} = _loop,
        %GameStopped{game_id: gid}
      ) do
    %Gameloop{
      game_id: gid,
      tick: 0
    }
  end
end
