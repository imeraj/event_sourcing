defmodule OrderFulfillmentProcessManager do
  @moduledoc false

  use GenServer

  def start_link(%{id: _id} = state) do
    GenServer.start_link(__MODULE__, state, name: OrderFulfillmentProcessManager)
  end

  def order_created(order_items) when is_list(order_items) do
    GenServer.call(__MODULE__, {:order_created, %{items: order_items}})
  end

  def payment_approved do
    GenServer.call(__MODULE__, :payment_approved)
  end

  def payment_declined do
    GenServer.call(__MODULE__, :payment_declined)
  end

  def order_canceled do
    GenServer.call(__MODULE__, :order_canceled)
  end

  def order_shipped do
    GenServer.call(__MODULE__, :order_shipped)
  end

  def payment_details_updated do
    GenServer.call(__MODULE__, :payment_details_updated)
  end

  # Callbacks
  @impl GenServer
  def init(%{id: id}) do
    state = %{id: id, status: :created, items: []}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:order_created, %{items: order_items}}, _from, state) do
    %{event_type: :order_created, items: order_items}

    cmds = Enum.map(order_items, fn item ->
      %{command_type: :reserver_quantity, aggregate: :stock_unit,
        quantity: item.quantity, sku: item.sku}
      end)

    state = %{state | status: :created, items: order_items}
    {:reply, cmds, state}
  end

  @impl GenServer
  def handle_call(:payment_approved, _from, state) do
    cmds = [
      %{command_type: :ship_order, aggregate: :order, id: state.id}
    ]
    state = %{state | status: :shipping}
    {:reply, cmds, state}
  end

  @impl GenServer
  def handle_call(:payment_declined, _from, state) do
    state = %{state | status: :payment_failure}
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call(:order_canceled, _from, state) do
    {:stop, :normal, %{}}
  end

  @impl GenServer
  def handle_call(:order_shipped, _from, state) do
    cmds = Enum.map(state.items, fn item ->
        %{command_type: :remove_quantity, aggregate: :stock_unit,
          quantity: item.quantity, sku: item.sku}
      end)
    {:stop, :normal, cmds, %{}}
  end

  @impl GenServer
  def handle_call(:payment_details_updated, _from, state) do
    cmds = [
      %{command_type: :ship_order, aggregate: :order, id: state.id}
    ]
    state = %{state | status: :shipping}
    {:reply, cmds, state}
  end
end