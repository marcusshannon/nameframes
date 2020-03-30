defmodule NameframesWeb.StorytellerPickComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    if assigns.is_storyteller do
      Phoenix.View.render(NameframesWeb.PageView, "storyteller_pick_storyteller.html", assigns)
    else
      Phoenix.View.render(NameframesWeb.PageView, "storyteller_pick_other.html", assigns)
    end
  end

  def update(assigns, socket) do
    is_storyteller = Games.is_storyteller?(assigns.game, assigns.player_id)
    player_names = Games.player_names(assigns.game)
    is_host = Games.is_host?(assigns.game, assigns.player_id)

    {:ok,
     socket
     |> assign(:player_names, player_names)
     |> assign(:is_host, is_host)
     |> assign(:hand, assigns.game.players[assigns.player_id].hand)
     |> assign(:is_storyteller, is_storyteller)
     |> assign(:pick, assigns[:pick])}
  end
end
