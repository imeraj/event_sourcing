defmodule FlightTracker.FlightNotifier do
  @moduledoc false
  use GenStage
  require Logger

  def start_link(flight_callsign) do
    GenStage.start_link(__MODULE__, flight_callsign, name: __MODULE__)
  end

  # Callbacks
  @impl GenStage
  def init(callsign) do
    {:consumer, callsign, subscribe_to: [FlightTracker.MessageBroadcaster]}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    Enum.each(events, &handle_event(Cloudevents.from_json!(&1), state))

    {:noreply, [], state}
  end

  # Helpers
  defp handle_event(
         %Cloudevents.Format.V_1_0.Event{
           type: "org.book.flighttracker.position_reported",
           data: dt
         },
         callsign
       ) do
    aircraft = FlightTracker.CraftProjector.get_state_by_icao(dt["icao_address"])
    IO.inspect(aircraft)

    # it's possible that we don't have the callsign yet
    case String.trim(Map.get(aircraft, :callsign, "")) do
      ^callsign ->
        Logger.info("#{aircraft.callsign}'s position: #{dt["latitude"]}, #{dt["longitude"]}")
        :ok

      _ ->
        :ok
    end
  end

  defp handle_event(_evt, _state), do: :ok
end
