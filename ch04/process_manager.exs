defmodule ProcessManager do
  @moduledoc false
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def batch_created(files) when is_list(files) do
    GenServer.call(__MODULE__, {:batch_created, files})
  end

  def file_processed(file) when is_map(file) do
    GenServer.call(__MODULE__, {:file_processed, file})
  end

  # Callbacks
  def init(%{id: id}) do
    state = %{
      id: id,
      files: %{},
      status: :idle
    }
    {:ok, state}
  end

  def handle_call({:batch_created, files}, _from, state) do
    f = Enum.map(files, fn f -> {f, :pending} end) |> Map.new()
    state = %{
     state
       | files: f,
       status: :processing
    }

    commands = Enum.map(files, fn f ->
      %{
        command_type: :process_file,
        file: f
      }
    end)

    {:reply, commands, state}
  end

  def handle_call({:file_processed, %{id: file_id, status: file_status}}, _from, state) do
    files = Map.update!(state.files, file_id, fn _ -> file_status end)

    state = %{
      state
      | files: files,
        status: determine_status(files)
    }

    {:reply, [], state}
  end

  # Helpers
  def determine_status(files) do
    cond do
      Enum.all?(files, fn {_f, status} -> status == :success end) -> :success
      Enum.any?(files, fn {_f, status} -> status == :error end) -> :error
      true -> :processing
    end
  end
end