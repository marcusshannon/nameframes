defmodule NameframesWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    case assigns.game.status do
      :lobby_small ->
        ~L"""
        <%= live_component @socket, NameframesWeb.LobbySmallComponent, Enum.to_list(assigns) %>
        """

      :lobby ->
        ~L"""
        <%= live_component @socket, NameframesWeb.LobbyComponent, Enum.to_list(assigns) %>
        """

      :storyteller_pick ->
        ~L"""
        <%= live_component @socket, NameframesWeb.StorytellerPickComponent, Enum.to_list(assigns) %>
        """

      :others_pick ->
        ~L"""
        <%= live_component @socket, NameframesWeb.OthersPickComponent, Enum.to_list(assigns) %>
        """

      :others_guess ->
        ~L"""
        <%= live_component @socket, NameframesWeb.OthersGuessComponent, Enum.to_list(assigns) %>
        """

      :results ->
        ~L"""
        <%= live_component @socket, NameframesWeb.ResultsComponent, Enum.to_list(assigns) %>
        """
    end
  end

  def mount(session, socket) do
    {:ok,
     socket
     |> assign(:player_id, session.player_id)
     |> assign(:nonce, Ecto.UUID.generate())}
  end

  def handle_params(%{"id" => game_id}, _uri, socket) do
    game = Nameframes.Store.get(game_id)
    Nameframes.Store.subscribe(game_id)

    {:noreply,
     socket
     |> assign(:game_id, game_id)
     |> assign(:game, game)
     |> assign(:view, get_view(game))}
  end

  def handle_info(game, socket) do
    {:noreply,
     socket
     |> assign(:game, game)
     |> assign(:nonce, Ecto.UUID.generate())}
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

    Nameframes.Store.send_event(
      socket.assigns.game_id,
      {:pick, socket.assigns.player_id, card}
    )

    {:noreply, socket}
  end

  def handle_event("guess", %{"card" => card}, socket) do
    {card, _} = Integer.parse(card)

    res =
      Nameframes.Store.send_event(
        socket.assigns.game_id,
        {:guess, socket.assigns.player_id, card}
      )

    {:noreply, socket}
  end

  def handle_event("ready", _value, socket) do
    Nameframes.Store.send_event(
      socket.assigns.game_id,
      {:ready, socket.assigns.player_id}
    )

    {:noreply, socket}
  end
end
