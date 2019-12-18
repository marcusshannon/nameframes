defmodule NameframesWeb.LobbySmallComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    Phoenix.View.render(NameframesWeb.PageView, "lobby_small.html", assigns)
  end

  def update(assigns, socket) do
    player_names = Games.player_names(assigns.game)

    {:ok,
     socket
     |> Map.put(:assigns, assigns)
     |> assign(:player_names, player_names)}
  end
end
