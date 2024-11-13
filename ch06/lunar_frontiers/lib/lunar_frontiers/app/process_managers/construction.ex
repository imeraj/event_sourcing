defmodule LunarFrontiers.App.ProcessManagers.Construction do
  @moduledoc false

  require Logger

  alias LunarFrontiers.App.Events.SiteSpawned
  alias LunarFrontiers.App.Events.ConstructionProgressed
  alias LunarFrontiers.App.Events.ConstructionCompleted
  alias LunarFrontiers.App.Events.BuildingSpawned
  alias LunarFrontiers.App.Commands.SpawnBuilding

  use Commanded.ProcessManagers.ProcessManager,
    application: LunarFrontiers.App.Application,
    name: __MODULE__

  @derive Jason.Encoder
  defstruct [:site_id, :tick_started, :ticks_completed, :ticks_required, :status]

  def interested?(%SiteSpawned{site_id: site_id}), do: {:start, site_id}
  def interested?(%ConstructionProgressed{site_id: site_id}), do: {:continue, site_id}
  def interested?(%ConstructionCompleted{site_id: site_id}), do: {:continue, site_id}
  def interested?(%BuildingSpawned{site_id: site_id}), do: {:stop, site_id}
  def interested?(_event), do: false

  # Command Dispatch
  def handle(
        %__MODULE__{},
        %ConstructionCompleted{} = event
      ) do
    %{
      site_id: site_id,
      site_type: site_type,
      location: location,
      player_id: player_id,
      tick: tick
    } = event

    %SpawnBuilding{
      site_id: site_id,
      site_type: site_type,
      location: location,
      tick: tick,
      player_id: player_id
    }
  end

  # By default skip any problematic events
  def error(error, _command_or_event, _failure_context) do
    Logger.error(fn ->
      "#{__MODULE__} encountered an error: #{inspect(error)}"
    end)

    :skip
  end
end
