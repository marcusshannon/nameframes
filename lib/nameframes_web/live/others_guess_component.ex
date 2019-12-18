defmodule NameframesWeb.OthersGuessComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    Phoenix.View.render(NameframesWeb.PageView, "others_guess.html", assigns)
  end

  def update(assigns, socket) do
    is_storyteller = Games.is_storyteller?(assigns.game, assigns.player_id)
    has_guessed = Games.has_guessed?(assigns.game, assigns.player_id)
    can_guess = not is_storyteller and not has_guessed
    guessable_cards = Games.show_guessable_cards(assigns.game, assigns.player_id)

    {:ok,
     socket
     |> assign(:guessable_cards, guessable_cards)
     |> assign(:pick, assigns.game.players[assigns.player_id].pick)
     |> assign(:is_storyteller, is_storyteller)
     |> assign(:can_guess, can_guess)}
  end
end
