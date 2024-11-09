defmodule FlightTracker.CraftProjector do
  @moduledoc false
  use GenStage
  require Logger

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_state_by_icao(icao) do
    case :ets.lookup(:aircraft_table, icao) do
      [{_icao, state}] ->
        state

      [] ->
        %{icao_address: icao}
    end
  end

  # Callbacks
  @impl GenStage
  def init(:ok) do
    :ets.new(:aircraft_table, [:named_table, :set, :public])

    {:consumer, :ok, subscribe_to: [FlightTracker.MessageBroadcaster]}
  end

  @impl GenStage
  def handle_events(events, _from, state) do
    Enum.each(events, &handle_event(Cloudevents.from_json!(&1)))

    {:noreply, [], state}
  end

  # Helpers
  defp handle_event(%Cloudevents.Format.V_1_0.Event{
         type: "org.book.flighttracker.aircraft_identified",
         data: dt
       }) do
    old_state = get_state_by_icao(dt["icao_address"])

    :ets.insert(
      :aircraft_table,
      {dt["icao_address"], Map.put(old_state, :callsign, dt["callsign"])}
    )
  end

  defp handle_event(%Cloudevents.Format.V_1_0.Event{
         type: "org.book.flighttracker.velocity_reported",
         data: dt
       }) do
    old_state = get_state_by_icao(dt["icao_address"])

    new_state =
      old_state
      |> Map.put(:heading, dt["heading"])
      |> Map.put(:ground_speed, dt["ground_speed"])
      |> Map.put(:vertical_rate, dt["vertical_rate"])

    :ets.insert(:aircraft_table, {dt["icao_address"], new_state})
  end

  defp handle_event(%Cloudevents.Format.V_1_0.Event{
         type: "org.book.flighttracker.position_reported",
         data: dt
       }) do
    old_state = get_state_by_icao(dt["icao_address"])

    # These coordinates are in CPR, not the familiar GPS format we're used to
    new_state =
      old_state
      |> Map.put(:longitude, dt["longitude"])
      |> Map.put(:latitude, dt["latitude"])
      |> Map.put(:altitude, dt["altitude"])

    :ets.insert(:aircraft_table, {dt["icao_address"], new_state})
  end

  defp handle_event(_e), do: false

  def aircraft_by_callsign(callsign) do
    :ets.select(:aircraft_table, [
      {
        {:"$1", :"$2"},
        [
          {:==, {:map_get, :callsign, :"$2"}, callsign}
        ],
        [:"$2"]
      }
    ])
    |> List.first()
  end
end
