defmodule Projectors.AccountBalance do
  @moduledoc false

  use GenServer
  require Logger

  def start_link(account_number) do
    GenServer.start_link(__MODULE__, account_number, name: via(account_number))
  end

  def apply_event(%{account_number: account} = event) when is_binary(account) do
    case Registry.lookup(Registry.AccountProjectors, account) do
      [{pid, _}] ->
        GenServer.cast(pid, {:handle_event, event})
      _ ->
        Logger.debug("Attempt to apply event to non-existent account, starting projector")
        {:ok, pid} = start_link(account)
        GenServer.cast(pid, {:handle_event, event})
    end
  end

  def lookup_balance(account_number) when is_binary(account_number) do
    case Registry.lookup(Registry.AccountProjectors, account_number) do
      [{pid, _}] ->
        GenServer.call(pid, :get_balance)
      _ ->
        {:error, :unknown_account}
    end
  end

  # Callbacks
  @impl true
  def init(account_number) do
    {:ok, %{balance: 0, account_number: account_number}}
  end

  @impl true
  def handle_cast({:handle_event, %{event_type: :amount_withdrawn, value: v}}, state) do
    %{balance: bal} = state
    {:noreply, %{state | balance: bal - v}}
  end

  def handle_cast({:handle_event, %{event_type: :amount_deposited, value: v}}, state) do
    %{balance: bal} = state
    {:noreply, %{state | balance: bal + v}}
  end

  def handle_cast({:handle_event, %{event_type: :fee_applied, value: v}}, state) do
    %{balance: bal} = state
    {:noreply, %{state | balance: bal - v}}
  end

  def handle_cast(_event, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_balance, _from, state) do
    {:reply, state.balance, state}
  end

  # Helpers
  defp via(account_number) do
    {:via, Registry, {Registry.AccountProjectors, account_number}}
  end
end