defmodule NameframesWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    IO.inspect(assigns.pick)

    case assigns.current_state do
      "LOBBY" ->
        Phoenix.View.render(
          NameframesWeb.PageView,
          "game.html",
          assigns
        )

      "STORYTELLER_PICK" ->
        case assigns.storyteller? do
          true ->
            Phoenix.View.render(
              NameframesWeb.PageView,
              "storyteller_pick.html",
              assigns
            )

          false ->
            Phoenix.View.render(
              NameframesWeb.PageView,
              "wait_for_storyteller_pick.html",
              assigns
            )
        end

      "OTHERS_PICK" ->
        case assigns.storyteller? do
          true ->
            Phoenix.View.render(
              NameframesWeb.PageView,
              "wait_for_others_pick.html",
              assigns
            )

          false ->
            case assigns.picked do
              true ->
                Phoenix.View.render(
                  NameframesWeb.PageView,
                  "wait_for_others_pick.html",
                  assigns
                )

              false ->
                Phoenix.View.render(
                  NameframesWeb.PageView,
                  "others_pick.html",
                  assigns
                )
            end
        end

      "VOTE" ->
        case assigns.storyteller? do
          true ->
            Phoenix.View.render(
              NameframesWeb.PageView,
              "storyteller_vote.html",
              assigns
            )

          false ->
            case assigns.guessed do
              false ->
                Phoenix.View.render(
                  NameframesWeb.PageView,
                  "others_vote.html",
                  assigns
                )

              true ->
                Phoenix.View.render(
                  NameframesWeb.PageView,
                  "storyteller_vote.html",
                  assigns
                )
            end
        end

      "ROUND_RESULTS" ->
        Phoenix.View.render(
          NameframesWeb.PageView,
          "round_results.html",
          assigns
        )
    end
  end

  def mount(session, socket) do
    {:ok,
     socket
     |> assign(:user_id, session.user_id)}
  end

  def get_assigns(socket, game) do
    socket
    |> assign(:game, game)
    |> assign(:names, Nameframes.Game.player_names(game))
    |> assign(:current_state, game.state)
    |> assign(:storyteller?, socket.assigns.user_id == Enum.at(game.order, game.current_turn))
    |> assign(:hand, game.players[socket.assigns.user_id].hand)
    |> assign(:picks, Nameframes.Game.get_picks(game))
    |> assign(:picks_to_player, Nameframes.Game.pick_to_player_map(game))
    |> assign(:card_to_user_guess, Nameframes.Game.card_to_user_guess(game))
    |> assign(:storyteller_id, Nameframes.Game.get_storyteller_id(game))
    |> assign(:ready, game.players[socket.assigns.user_id].ready)
    |> assign(:leaderboard, Nameframes.Game.leaderboard(game))
    |> assign(:picked, not is_nil(game.players[socket.assigns.user_id].pick))
    |> assign(:guessed, not is_nil(game.players[socket.assigns.user_id].guess))
    |> assign(:pick, game.players[socket.assigns.user_id].pick)
  end

  def handle_params(params, _uri, socket) do
    game_id = params["id"]
    game = Nameframes.Store.get(game_id)

    Nameframes.Store.subscribe(params["id"])

    {:noreply,
     socket
     |> assign(:game_id, game_id)
     |> get_assigns(game)}
  end

  def handle_info(game, socket) do
    {:noreply, get_assigns(socket, game)}
  end

  def handle_event("start", _value, socket) do
    Nameframes.Store.cast(socket.assigns.game_id, :start_game)
    {:noreply, socket}
  end

  def handle_event("select", value, socket) do
    {card, _} = Integer.parse(value["card"])

    {:noreply, assign(socket, :select, card)}
  end

  def handle_event("guess_select", value, socket) do
    {card, _} = Integer.parse(value["card"])

    own_card = socket.assigns.game.players[socket.assigns.user_id].pick

    case own_card == card do
      true ->
        {:noreply, socket}

      false ->
        {:noreply, assign(socket, :guess_selection, card)}
    end
  end

  def handle_event("storyteller_pick", value, socket) do
    {card, _} = Integer.parse(value["card"])

    Nameframes.Store.cast(
      socket.assigns.game_id,
      {:storyteller_pick, socket.assigns.user_id, card}
    )

    {:noreply, socket}
  end

  def handle_event("others_pick", value, socket) do
    IO.inspect(value)
    {card, _} = Integer.parse(value["card"])

    Nameframes.Store.cast(
      socket.assigns.game_id,
      {:others_pick, socket.assigns.user_id, card}
    )

    {:noreply, socket}
  end

  def handle_event("others_guess", value, socket) do
    IO.inspect(value)
    {card, _} = Integer.parse(value["card"])

    Nameframes.Store.cast(
      socket.assigns.game_id,
      {:others_guess, socket.assigns.user_id, card}
    )

    {:noreply, socket}
  end

  def handle_event("ready", _value, socket) do
    Nameframes.Store.cast(
      socket.assigns.game_id,
      {:ready, socket.assigns.user_id}
    )

    {:noreply, socket |> assign(:guess_selection, nil) |> assign(:select, nil)}
  end
end
