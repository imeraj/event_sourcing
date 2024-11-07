defmodule FlightTracker.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {FlightTracker.FileInjector, ["sample_cloudevents.json"]},
      FlightTracker.MessageBroadcaster,
      FlightTracker.CraftProjector,
      {FlightTracker.FlightNotifier, ["AMC421"]}
    ]

    opts = [strategy: :rest_for_one, name: FlightTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
