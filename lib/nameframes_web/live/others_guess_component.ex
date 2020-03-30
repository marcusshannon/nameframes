defmodule NameframesWeb.OthersGuessComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    if assigns.is_storyteller do
      Phoenix.View.render(NameframesWeb.PageView, "others_guess_storyteller.html", assigns)
    else
      if assigns.can_guess do
        Phoenix.View.render(NameframesWeb.PageView, "others_guess_other.html", assigns)
      else
        Phoenix.View.render(NameframesWeb.PageView, "others_guess_other_guessed.html", assigns)
      end
    end
  end

  def update(assigns, socket) do
    is_storyteller = Games.is_storyteller?(assigns.game, assigns.player_id)
    has_guessed = Games.has_guessed?(assigns.game, assigns.player_id)
    can_guess = not is_storyteller and not has_guessed
    guessable_cards = Games.show_guessable_cards(assigns.game, assigns.player_id)
    locked_guess = assigns.game.players[assigns.player_id].guess

    {:ok,
     socket
     |> assign(:guessable_cards, guessable_cards)
     |> assign(:locked_pick, assigns.game.players[assigns.player_id].pick)
     |> assign(:is_storyteller, is_storyteller)
     |> assign(:can_guess, can_guess)
     |> assign(:locked_guess, locked_guess)
     |> assign(:guess, assigns[:guess])}
  end
end
