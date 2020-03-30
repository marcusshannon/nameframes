defmodule NameframesWeb.ResultsComponent do
  use Phoenix.LiveComponent
  alias Nameframes.Games

  def render(assigns) do
    Phoenix.View.render(NameframesWeb.PageView, "results.html", assigns)
  end

  def update(assigns, socket) do
    storyteller_id = Games.get_storyteller_id(assigns.game)
    storyteller_name = assigns.game.players[storyteller_id].name
    storyteller_card = assigns.game.players[storyteller_id].pick

    is_storyteller = Games.is_storyteller?(assigns.game, assigns.player_id)
    has_guessed = Games.has_guessed?(assigns.game, assigns.player_id)
    can_guess = not is_storyteller and not has_guessed
    guessable_cards = Games.guessable_cards(assigns.game, assigns.player_id)

    display_others = Games.display_others(assigns.game)
    storyteller_guesses = Games.storyteller_guesses(assigns.game)

    player_guesses = Games.guesses_for_player(assigns.game, assigns.player_id)
    leaderboard = Games.leaderboard(assigns.game)

    {:ok,
     socket
     |> assign(:storyteller_guesses, storyteller_guesses)
     |> assign(:storyteller_id, storyteller_id)
     |> assign(:storyteller_name, storyteller_name)
     |> assign(:storyteller_card, storyteller_card)
     |> assign(:guessable_cards, guessable_cards)
     |> assign(:pick, assigns.game.players[assigns.player_id].pick)
     |> assign(:is_storyteller, is_storyteller)
     |> assign(:can_guess, can_guess)
     |> assign(:player_guesses, player_guesses)
     |> assign(:leaderboard, leaderboard)
     |> assign(:is_ready, assigns.game.players[assigns.player_id].ready)
     |> assign(:game, assigns.game)
     |> assign(:player_id, assigns.player_id)
     |> assign(:display_others, display_others)}
  end
end
