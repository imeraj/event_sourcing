defmodule FlightTracker.FileInjector do
  @moduledoc false
  use GenServer
  require Logger

  def start_link(file) do
    GenServer.start_link(__MODULE__, file, name: __MODULE__)
  end

  # Callbacks
  @impl GenServer
  def init(file) do
    Process.send_after(self(), :read_file, 2_000)
    {:ok, file}
  end

  @impl GenServer
  def handle_info(:read_file, file) do
    file = Path.join([:code.priv_dir(:flight_tracker), "data", file])

    File.stream!(file)
    |> Enum.map(&String.trim/1)
    |> Enum.each(&FlightTracker.MessageBroadcaster.broadcast_event(&1))

    {:noreply, file}
  end
end
