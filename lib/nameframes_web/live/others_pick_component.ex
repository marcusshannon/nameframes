defmodule NameframesWeb.OthersPickComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    Phoenix.View.render(NameframesWeb.PageView, "others_pick.html", assigns)
  end

  def update(assigns, socket) do
    is_storyteller = Games.is_storyteller?(assigns.game, assigns.player_id)
    player_names = Games.player_names(assigns.game)
    is_host = Games.is_host?(assigns.game, assigns.player_id)
    has_picked = Games.has_picked?(assigns.game, assigns.player_id)
    can_pick = not is_storyteller and not has_picked

    {:ok,
     socket
     |> assign(:player_names, player_names)
     |> assign(:is_host, is_host)
     |> assign(:hand, assigns.game.players[assigns.player_id].hand)
     |> assign(:is_storyteller, is_storyteller)
     |> assign(:can_pick, can_pick)}
  end
end
