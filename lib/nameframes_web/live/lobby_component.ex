defmodule NameframesWeb.LobbyComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    Phoenix.View.render(NameframesWeb.PageView, "lobby.html", assigns)
  end

  def update(assigns, socket) do
    player_names = Games.player_names(assigns.game)
    is_host = Games.is_host?(assigns.game, assigns.player_id)

    {:ok,
     socket
     |> Map.put(:assigns, assigns)
     |> assign(:player_names, player_names)
     |> assign(:is_host, is_host)}
  end
end
