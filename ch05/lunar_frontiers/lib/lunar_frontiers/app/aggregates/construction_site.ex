defmodule LunarFrontiers.App.Aggregates.ConstructionSite do
  @moduledoc false

  alias __MODULE__

  alias LunarFrontiers.App.Commands.SpawnSite
  alias LunarFrontiers.App.Commands.AdvanceConstruction

  alias LunarFrontiers.App.Events.SiteSpawned
  alias LunarFrontiers.App.Events.ConstructionProgressed
  alias LunarFrontiers.App.Events.ConstructionCompleted

  alias Commanded.Aggregate.Multi

  defstruct [
    :site_id,
    :site_type,
    :location,
    :required_ticks,
    :completed_ticks,
    :created_ticks,
    :player_id,
    :completed,
    :completed_tick
  ]

  # Command Handlers
  def execute(%ConstructionSite{} = _site, %SpawnSite{} = command) do
    %{
      site_id: id,
      site_type: type,
      completion_ticks: ticks,
      location: loc,
      tick: now_tick,
      player_id: player_id
    } = command

    event = %SiteSpawned{
      site_id: id,
      site_type: type,
      location: loc,
      tick: now_tick,
      remaining_ticks: ticks,
      player_id: player_id
    }

    {:ok, event}
  end

  def execute(%ConstructionSite{} = site, %AdvanceConstruction{} = cmd) do
    site
    |> Multi.new()
    |> Multi.execute(&progress_construction(&1, cmd.tick, cmd.advance_ticks))
    |> Multi.execute(&check_completed(&1, cmd.tick))
  end

  # State Mutators
  def apply(%ConstructionSite{} = _site, %SiteSpawned{} = event) do
    %{
      site_id: id,
      site_type: type,
      location: loc,
      tick: now_tick,
      remaining_ticks: ticks,
      player_id: player_id
    } = event

    %ConstructionSite{
      site_id: id,
      site_type: type,
      location: loc,
      required_ticks: ticks,
      created_ticks: now_tick,
      completed_ticks: 0,
      completed: false
    }
  end

  def apply(%ConstructionSite{} = site, %ConstructionProgressed{} = event) do
    %ConstructionSite{
      site
      | completed_ticks: event.completed_ticks
    }
  end

  def apply(%ConstructionSite{} = site, %ConstructionCompleted{} = event) do
    %ConstructionSite{
      site
      | completed_tick: event.tick,
        completed: true
    }
  end

  # Private helpers
  defp progress_construction(
         %ConstructionSite{completed_ticks: c, required_ticks: r} = site,
         tick,
         advance_ticks
       )
       when c < r do
    %{
      site_id: id,
      site_type: type,
      location: location,
      required_ticks: required_ticks,
      completed_ticks: completed_ticks
    } = site

    event = %ConstructionProgressed{
      site_id: id,
      site_type: type,
      location: location,
      completed_ticks: completed_ticks + advance_ticks,
      required_ticks: required_ticks,
      tick: tick
    }

    {:ok, event}
  end

  defp progress_construction(%ConstructionSite{} = _site, _tick, _advance_tick), do: :ok

  defp check_completed(%ConstructionSite{completed_ticks: c, required_ticks: r} = site, tick)
       when c >= r do
    %{site_id: id, site_type: type, location: location, player_id: player_id} = site

    event = %ConstructionCompleted{
      site_id: id,
      site_type: type,
      location: location,
      tick: tick,
      player_id: player_id
    }

    {:ok, event}
  end

  defp check_completed(%ConstructionSite{} = _site, _tick), do: :ok
end
