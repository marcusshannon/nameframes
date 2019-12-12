defmodule Nameframes.Store do
  use GenServer

  def registry(id) do
    {:via, Registry, {Nameframes.Store.Registry, id}}
  end

  def exists?(id) do
    case Registry.lookup(Nameframes.Store.Registry, id) do
      [] -> false
      _ -> true
    end
  end

  def new(id, state) do
    DynamicSupervisor.start_child(Nameframes.Store.Supervisor, %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [id, state]}
    })
  end

  def get(id) do
    GenServer.call(registry(id), :get)
  end

  def start_link(id, state) do
    GenServer.start_link(__MODULE__, state, name: registry(id))
  end

  def update(id, state) do
    GenServer.cast(registry(id), {:update, state})
    broadcast_change(id, state)
  end

  # client
  def cast(id, msg) do
    GenServer.cast(registry(id), msg)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update, newState}, _) do
    {:noreply, newState}
  end

  def handle_cast({:join, user}, state) do
    nextState = Nameframes.Game.join_game(state, user)
    finish_cast(nextState)
  end

  def handle_cast({:storyteller_pick, user_id, card}, state) do
    nextState = Nameframes.Game.pick_card(state, user_id, card) |> Map.put(:state, "OTHERS_PICK")
    finish_cast(nextState)
  end

  def handle_cast({:ready, user_id}, state) do
    nextState =
      Nameframes.Game.update_player(state, user_id, Map.put(state.players[user_id], :ready, true))

    all_ready = Nameframes.Game.all_ready(nextState)

    case all_ready do
      true ->
        nextState = nextState |> Nameframes.Game.next_round()
        finish_cast(nextState)

      false ->
        finish_cast(nextState)
    end
  end

  def handle_cast({:others_pick, user_id, card}, state) do
    nextState = Nameframes.Game.pick_card(state, user_id, card)
    all_picked = Nameframes.Game.all_picked(nextState)

    case all_picked do
      true ->
        updated_state = nextState |> Map.put(:state, "VOTE")
        finish_cast(updated_state)

      false ->
        finish_cast(nextState)
    end
  end

  def handle_cast({:others_guess, user_id, card}, state) do
    nextState = Nameframes.Game.guess_card(state, user_id, card)
    all_guessed = Nameframes.Game.all_guessed(nextState)

    case all_guessed do
      true ->
        updated_state =
          nextState |> Map.put(:state, "ROUND_RESULTS") |> Nameframes.Game.score_round()

        finish_cast(updated_state)

      false ->
        finish_cast(nextState)
    end
  end

  def finish_cast(nextState) do
    broadcast_change(hd(Registry.keys(Nameframes.Store.Registry, self())), nextState)
    {:noreply, nextState}
  end

  def handle_cast(:start_game, state) do
    nextState =
      state
      |> Map.put(:state, "STORYTELLER_PICK")
      |> Nameframes.Game.start_game()

    broadcast_change(hd(Registry.keys(Nameframes.Store.Registry, self())), nextState)
    {:noreply, nextState}
  end

  def subscribe(game_id) do
    Phoenix.PubSub.subscribe(Nameframes.PubSub, game_id)
  end

  defp broadcast_change(id, state) do
    Phoenix.PubSub.broadcast(Nameframes.PubSub, id, state)
    state
  end
end
