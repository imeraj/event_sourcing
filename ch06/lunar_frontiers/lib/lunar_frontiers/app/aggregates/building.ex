defmodule LunarFrontiers.App.Aggregates.Building do
  @moduledoc false

  alias LunarFrontiers.App.Events.BuildingSpawned
  alias LunarFrontiers.App.Commands.SpawnBuilding
  alias __MODULE__

  defstruct [:site_id, :site_type, :location, :player_id]

  # Command Handlers
  def execute(%Building{} = _bldg, %SpawnBuilding{} = cmd) do
    %{site_id: site_id, site_type: type, location: loc, player_id: player_id} = cmd

    event = %BuildingSpawned{
      site_id: site_id,
      site_type: type,
      location: loc,
      player_id: player_id
    }

    {:ok, event}
  end

  # State Mutators
  def apply(%Building{} = _bldg, %BuildingSpawned{} = event) do
    %{site_id: site_id, site_type: site_type, location: loc, player_id: player_id} = event

    %Building{site_id: site_id, site_type: site_type, location: loc, player_id: player_id}
  end
end
