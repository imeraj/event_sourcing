defmodule LunarFrontiers.App.ProcessManagers.GameLoop do
  @moduledoc false

  require Logger

  alias LunarFrontiers.App.Commands.AdvanceConstruction
  alias LunarFrontiers.App.Events.GameloopAdvanced
  alias LunarFrontiers.App.Events.GameStarted
  alias LunarFrontiers.App.Events.ConstructionCompleted
  alias LunarFrontiers.App.Events.SiteSpawned
  alias LunarFrontiers.App.Events.GameStopped

  use Commanded.ProcessManagers.ProcessManager,
    application: LunarFrontiers.App.Application,
    name: __MODULE__

  @derive Jason.Encoder
  defstruct [:current_tick, :game_id, active_construction_sites: []]

  # Process routing
  def interested?(%GameStarted{game_id: gid}), do: {:start, gid}
  def interested?(%SiteSpawned{game_id: gid}), do: {:continue, gid}
  def interested?(%ConstructionCompleted{game_id: gid}), do: {:continue, gid}
  def interested?(%GameloopAdvanced{game_id: gid}), do: {:continue, gid}
  def interested?(%GameStopped{game_id: gid}), do: {:stop, gid}
  def interested?(_), do: false

  # Command dispatch
  def handle(%__MODULE__{} = state, %GameloopAdvanced{tick: tick}) do
    sites = state.active_construction_sites

    construction_cmds =
      sites
      |> Enum.map(fn site_id ->
        %AdvanceConstruction{
          site_id: site_id,
          tick: tick,
          advance_ticks: 1
        }
      end)

    construction_cmds
  end

  # State mutators
  def apply(%__MODULE__{} = state, %GameloopAdvanced{tick: tick}) do
    %__MODULE__{state | current_tick: tick}
  end

  def apply(%__MODULE__{} = state, %GameStarted{game_id: gid}) do
    %__MODULE__{state | game_id: gid, current_tick: 0}
  end

  def apply(%__MODULE__{} = state, %SiteSpawned{site_id: sid, tick: t}) do
    %__MODULE__{
      state
      | active_construction_sites: [sid | state.active_construction_sites],
        current_tick: t
    }
  end

  def apply(%__MODULE__{} = state, %ConstructionCompleted{site_id: sid, tick: t}) do
    %__MODULE__{
      state
      | current_tick: t,
        active_construction_sites: state.active_construction_sites -- [sid]
    }
  end

  def apply(%__MODULE__{} = state, %GameStopped{game_id: gid}) do
    %__MODULE__{state | game_id: gid, current_tick: 0, active_construction_sites: []}
  end

  # By default skip any problematic events
  def error(error, _command_or_event, _failure_context) do
    Logger.error(fn ->
      "#{__MODULE__} encountered an error: #{inspect(error)}"
    end)

    :skip
  end
end
