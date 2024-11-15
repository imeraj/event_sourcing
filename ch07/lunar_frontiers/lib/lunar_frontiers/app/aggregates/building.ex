defmodule LunarFrontiers.App.Aggregates.Building do
  @moduledoc false

  alias LunarFrontiers.App.Events.BuildingSpawned
  alias LunarFrontiers.App.Events.ConstructionProgressed
  alias LunarFrontiers.App.Commands.SpawnBuilding
  alias LunarFrontiers.App.Commands.AdvanceConstruction
  alias LunarFrontiers.App.Events.ConstructionCompleted
  alias __MODULE__

  alias Commanded.Aggregate.Multi

  defstruct [:site_id, :site_type, :location, :game_id, :player_id, :created_tick, :construction_remaining]

  # Command Handlers
  def execute(%Building{} = _bldg, %SpawnBuilding.V2{} = cmd) do
    %{
      site_id: site_id,
      site_type: type,
      location: loc,
      player_id: player_id,
      game_id: game_id,
      completion_ticks: completion_ticks
    } = cmd

    event = %BuildingSpawned.V2{
      site_id: site_id,
      site_type: type,
      location: loc,
      player_id: player_id,
      game_id: game_id,
      completion_ticks: completion_ticks
    }

    {:ok, event}
  end

  def execute(%Building{} = building, %AdvanceConstruction{} = cmd) do
    building
    |> Multi.new()
    |> Multi.execute(&progress_construction(&1, cmd.tick, cmd.advance_ticks))
    |> Multi.execute(&check_completed(&1, cmd.tick))
  end

  # State Mutators
  def apply(%Building{} = _building, %BuildingSpawned.V2{} = event) do
    %{
      site_id: site_id,
      site_type: site_type,
      location: loc,
      player_id: player_id,
      game_id: game_id,
      completion_ticks: completion_ticks
    } = event

    %Building{
      site_id: site_id,
      site_type: site_type,
      location: loc,
      player_id: player_id,
      game_id: game_id,
      construction_remaining: completion_ticks
    }
  end

  # State Mutators
  def apply(%Building{} = building, %ConstructionProgressed{} = event) do
    %Building{
      building
      | construction_remaining: max(building.construction_remaining - event.completed_ticks, 0)
    }
  end

  def apply(%Building{} = building, %ConstructionCompleted{} = _event) do
    %Building{building | construction_remaining: 0}
  end

  # Private helpers
  defp progress_construction(
         %Building{construction_remaining: 0} = _building,
         _tick,
         _advance_tick
       ),
       do: :ok

  defp progress_construction(
         %Building{} = building,
         tick,
         advance_ticks
       ) do
    %{
      site_id: id,
      site_type: type,
      game_id: game_id,
      location: location,
      construction_remaining: construction_remaining
    } = building

    event = %ConstructionProgressed{
      site_id: id,
      site_type: type,
      game_id: game_id,
      location: location,
      completed_ticks: advance_ticks,
      required_ticks: construction_remaining,
      tick: tick
    }

    {:ok, event}
  end

  defp check_completed(%Building{construction_remaining: 0} = building, tick) do
    %{site_id: id, site_type: type, game_id: game_id, location: location, player_id: player_id} =
      building

    event = %ConstructionCompleted{
      site_id: id,
      site_type: type,
      game_id: game_id,
      location: location,
      tick: tick,
      player_id: player_id
    }

    {:ok, event}
  end

  defp check_completed(%Building{} = _building, _tick), do: :ok
end
