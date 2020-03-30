defmodule NameframesWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    # this is where you should get all your derived data
    # or inside the component, which makes sense to compartmentalize the deriving
    assigns = [component: get_component(assigns)] ++ Enum.to_list(assigns)
    Phoenix.View.render(NameframesWeb.PageView, "component.html", assigns)
  end

  def get_component(state) do
    case state.game.status do
      :lobby_small ->
        NameframesWeb.LobbyComponent

      :lobby ->
        NameframesWeb.LobbyComponent

      :storyteller_pick ->
        NameframesWeb.StorytellerPickComponent

      :others_pick ->
        NameframesWeb.OthersPickComponent

      :others_guess ->
        NameframesWeb.OthersGuessComponent

      :results ->
        NameframesWeb.ResultsComponent
    end
  end

  def mount(session, socket) do
    game_id = session.game_id
    game = Nameframes.Store.get(game_id)
    Nameframes.Store.subscribe(game_id)

    {:ok,
     socket
     |> assign(:player_id, session.fingerprint)
     |> assign(:game_id, game_id)
     |> assign(:game, game)
     |> assign(:view, get_view(game))}
  end

  def handle_info(game, socket) do
    {:noreply,
     socket
     |> assign(:game, game)}
  end

  def get_view(game) do
    game.status
  end

  # Event handlers
  def handle_event("start", _value, socket) do
    Nameframes.Store.send_event(socket.assigns.game_id, {:start, socket.assigns.player_id})

    {:noreply, socket}
  end

  def handle_event("pick", %{"card" => card}, socket) do
    {card, _} = Integer.parse(card)

    {:noreply,
     socket
     |> assign(:pick, card)}
  end

  def handle_event("confirm_pick", _, socket) do
    Nameframes.Store.send_event(
      socket.assigns.game_id,
      {:pick, socket.assigns.player_id, socket.assigns.pick}
    )

    {:noreply,
     socket
     |> assign(:pick, nil)}
  end

  def handle_event("guess", %{"card" => card}, socket) do
    {card, _} = Integer.parse(card)

    {:noreply, socket |> assign(:guess, card)}
  end

  def handle_event("confirm_guess", _, socket) do
    Nameframes.Store.send_event(
      socket.assigns.game_id,
      {:guess, socket.assigns.player_id, socket.assigns.guess}
    )

    {:noreply, socket |> assign(:guess, nil)}
  end

  def handle_event("ready", _value, socket) do
    Nameframes.Store.send_event(
      socket.assigns.game_id,
      {:ready, socket.assigns.player_id}
    )

    {:noreply, socket}
  end
end
