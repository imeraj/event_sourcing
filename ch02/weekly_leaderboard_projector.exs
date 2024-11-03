defmodule Projectors.WeeklyLeaderboard do
  @moduledoc false

  use GenServer
  require Logger

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def apply_event(pid, evt) do
    GenServer.cast(pid, {:handle_event, evt})
  end

  def get_top10(pid) do
    GenServer.call(pid, :get_top10)
  end

  def get_score(pid, attacker) do
    GenServer.call(pid, {:get_score, attacker})
  end

  # Callbacks
  @impl true
  def init(_) do
    {:ok, %{scores: %{}, top10: []}}
  end

  @impl true
  def handle_call(:get_top10, _from, state) do
    {:reply, state.scores, state}
  end

  def handle_call({:get_score, attacker}, _from, state) do
    {:reply, Map.get(state.scores, attacker, 0), state}
  end

  @impl true
  def handle_cast({:handle_event, %{event_type: :zombie_killed, attacker: attacker}}, state) do
    new_scores = Map.update(state.scores, attacker, 1, &(&1+1))
    {:noreply, %{state | scores: new_scores, top10: rerank(new_scores)}}
  end

  def handle_cast({:handle_event, %{event_type: :week_completed}}, _state) do
    {:noreply, %{scores: %{}, top10: []}}
  end

  def handle_event(_event, state), do: {:noreply, state}

  # Helpers
  defp rerank(scores) do
    scores
    |> Map.to_list()
    |> Enum.sort(fn {_k1, v1}, {_k2, v2} -> v1 >= v2 end)
    |> Enum.take(10)
  end
end