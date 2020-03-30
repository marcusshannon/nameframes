defmodule NameframesWeb.LobbyComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    Phoenix.View.render(NameframesWeb.ComponentView, "live_lobby.html", assigns)
  end

  def update(assigns, socket) do
    player_names = Games.player_names(assigns.game)
    is_host = Games.is_host?(assigns.game, assigns.player_id)
    can_start_game? = is_host and assigns.game.status === :lobby
    host_id = assigns.game.host
    host_name = assigns.game.players[host_id].name

    {:ok,
     socket
     |> Map.put(:assigns, assigns)
     |> assign(:player_names, player_names)
     |> assign(:is_host, is_host)
     |> assign(:can_start_game?, can_start_game?)
     |> assign(:host_name, host_name)}
  end
end
