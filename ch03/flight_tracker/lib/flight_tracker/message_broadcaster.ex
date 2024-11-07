defmodule FlightTracker.MessageBroadcaster do
  @moduledoc false
  use GenStage
  require Logger

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Injects a raw message that is not in cloud event format
  """
  def broadcast_message(message) do
    GenStage.call(__MODULE__, {:notify_message, message})
  end

  @doc """
  Injects a cloud event to be published to the stage pipeline
  """
  def broadcast_event(event) do
    GenStage.call(__MODULE__, {:notify_event, event})
  end

  # Callbacks
  @impl GenStage
  def init(:ok) do
    {:producer, :ok, dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl GenStage
  def handle_call({:notify_message, message}, _from, state) do
    {:reply, :ok, [to_event(message)], state}
  end

  @impl GenStage
  def handle_call({:notify_event, event}, _from, state) do
    {:reply, :ok, [event], state}
  end

  @impl GenStage
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  # Helpers
  defp to_event(%{
         type: :aircraft_identified,
         message:
           %{
             icao_address: _icao,
             callsign: _callsign,
             emitter_category: _cat
           } = msg
       }) do
    new_cloudevent("aircraft_idetified", msg)
  end

  defp to_event(%{type: :squawk_received, message: %{squawk: _squawk, icao_address: _icao} = msg}) do
    new_cloudevent("squawk_received", msg)
  end

  defp to_event(%{
         type: :position_reported,
         message: %{
           icao_address: icao,
           position: %{
             altitude: alt,
             longitude: long,
             latitude: lat
           }
         }
       }) do
    new_cloudevent("position_reported", %{
      altitude: alt,
      longitude: long,
      latitude: lat,
      icao_address: icao
    })
  end

  defp to_event(%{
         type: :velocity_reported,
         message:
           %{heading: _head, ground_speed: _gs, vertical_rate: _vr, vertical_rate_source: vrs} =
             msg
       }) do
    source =
      case vrs do
        :barometric_pressure -> "barometric"
        :geometric -> "geometric"
        _ -> "unknown"
      end

    new_cloudevent("velocity_reported", %{msg | vertical_rate_source: source})
  end

  defp to_event(msg) do
    Logger.error("Unknown message: #{inspect(msg)}")
    %{}
  end

  defp new_cloudevent(type, data) do
    %{
      "specversion" => "1.0",
      "type" => "org.book.flighttracker.#{String.downcase(type)}",
      "source" => "radio_aggregator",
      "id" => UUID.uuid4(),
      "datacontenttype" => "application/json",
      "time" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "data" => data
    }
    |> Cloudevents.from_map!()
    |> Cloudevents.to_json()
  end
end
