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

  # client
  def cast(id, msg) do
    GenServer.cast(registry(id), msg)
  end

  def call(id, msg) do
    GenServer.call(registry(id), msg)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def send_event(id, event) do
    GenServer.cast(registry(id), event)
  end


  def update(id, next_state) do
    GenServer.cast(registry(id), {:update, next_state})
  end

  # server
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, _player_id, _player_name} = event, _from, game) do
    case Nameframes.Games.event(game, event) do
      {:ok, nextGame} ->
        broadcast_change(hd(Registry.keys(Nameframes.Store.Registry, self())), nextGame)
        {:reply, :ok, nextGame}

      _ ->
        {:reply, :error, game}
    end
  end

  def handle_cast({:update, next_state}, _) do
    {:noreply, next_state}
  end

  def handle_cast(event, game) do
    case Nameframes.Games.event(game, event) do
      {:ok, nextGame} ->
        broadcast_change(hd(Registry.keys(Nameframes.Store.Registry, self())), nextGame)
        {:noreply, nextGame}

      _ ->
        {:noreply, game}
    end
  end

  def subscribe(game_id) do
    Phoenix.PubSub.subscribe(Nameframes.PubSub, game_id)
  end

  defp broadcast_change(id, state) do
    Phoenix.PubSub.broadcast(Nameframes.PubSub, id, state)
    state
  end
end
