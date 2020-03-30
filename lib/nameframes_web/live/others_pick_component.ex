defmodule NameframesWeb.OthersPickComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    if assigns.is_storyteller do
      Phoenix.View.render(NameframesWeb.PageView, "others_pick_storyteller.html", assigns)
    else
      if assigns.can_pick do
        Phoenix.View.render(NameframesWeb.PageView, "others_pick_other.html", assigns)
      else
        Phoenix.View.render(NameframesWeb.PageView, "others_pick_other_picked.html", assigns)
      end
    end
  end

  def update(assigns, socket) do
    is_storyteller = Games.is_storyteller?(assigns.game, assigns.player_id)
    player_names = Games.player_names(assigns.game)
    is_host = Games.is_host?(assigns.game, assigns.player_id)
    has_picked = Games.has_picked?(assigns.game, assigns.player_id)
    can_pick = not is_storyteller and not has_picked
    locked_pick = assigns.game.players[assigns.player_id].pick

    {:ok,
     socket
     |> assign(:player_names, player_names)
     |> assign(:is_host, is_host)
     |> assign(:hand, assigns.game.players[assigns.player_id].hand)
     |> assign(:is_storyteller, is_storyteller)
     |> assign(:can_pick, can_pick)
     |> assign(:pick, assigns[:pick])
     |> assign(:locked_pick, locked_pick)}
  end
end
