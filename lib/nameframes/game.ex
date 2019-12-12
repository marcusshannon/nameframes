# player is game state related to a user

defmodule Nameframes.Game do
  def new_player(user) do
    %{
      id: user.id,
      name: user.name,
      hand: [],
      pick: nil,
      guess: nil,
      points: 0,
      ready: false
    }
  end

  def new_user(user_id) do
    %{
      id: user_id
    }
  end

  def new_deck() do
    Enum.to_list(1..98)
    |> Enum.shuffle()
  end

  def new_game(user) do
    %{
      state: "LOBBY",
      host: user.id,
      players: %{user.id => new_player(user)},
      deck: new_deck(),
      discard: [],
      current_turn: 0,
      order: []
    }
  end

  def join_game(game, user) do
    Map.update!(game, :players, &Map.put(&1, user.id, new_player(user)))
  end

  def set_order(game) do
    shuffled_players =
      Map.keys(game.players)
      |> Enum.shuffle()

    Map.put(game, :order, shuffled_players)
  end

  def assign_cards(players, [hand | rest_cards], [user_id | rest_users]) do
    updated_players = Map.update!(players, user_id, &Map.put(&1, :hand, hand))
    assign_cards(updated_players, rest_cards, rest_users)
  end

  def assign_cards(players, _, _) do
    players
  end

  def all_picked(game) do
    Enum.all?(game.players, fn {user_id, player} ->
      not is_nil(player.pick)
    end)
  end

  def all_ready(game) do
    Enum.all?(game.players, fn {user_id, player} ->
      player.ready
    end)
  end

  def deal(game) do
    number_of_players = length(game.order)
    take_amount = number_of_players * 6
    dealt_cards = Enum.take(game.deck, take_amount) |> Enum.chunk_every(6)

    updated_deck = Enum.drop(game.deck, take_amount)
    updated_players = assign_cards(game.players, dealt_cards, game.order)

    Map.merge(game, %{deck: updated_deck, players: updated_players})
  end

  def pick_card(game, user_id, card) do
    already_picked? = not is_nil(game.players[user_id].pick)

    case already_picked? do
      true ->
        game

      false ->
        player = game.players[user_id]
        updated_hand = List.delete(player.hand, card)

        IO.inspect(updated_hand)

        updated_player =
          Map.merge(player, %{
            hand: updated_hand,
            pick: card
          })

        updated_players = Map.merge(game.players, %{user_id => updated_player})

        Map.merge(game, %{players: updated_players})
    end
  end

  def update_player(game, user_id, updated_player) do
    updated_players = Map.merge(game.players, %{user_id => updated_player})
    Map.merge(game, %{players: updated_players})
  end

  def guess_card(game, user_id, card) do
    player = game.players[user_id]

    updated_player =
      Map.merge(player, %{
        guess: card
      })

    update_player(game, user_id, updated_player)
  end

  def get_storyteller_id(game) do
    Enum.at(game.order, game.current_turn)
  end

  def get_storyteller(game) do
    storyteller_id = Enum.at(game.order, game.current_turn)
    game.players[storyteller_id]
  end

  def all_vote_for_storyteller(game) do
    storyteller_id = get_storyteller_id(game)
    storyteller = get_storyteller(game)
    other_players = List.delete(game.order, storyteller_id)

    guesses =
      Enum.map(other_players, fn user_id ->
        game.players[user_id].guess
      end)

    filtered_guesses =
      Enum.filter(guesses, fn guess ->
        guess != storyteller.pick
      end)

    length(filtered_guesses) == 0
  end

  def none_vote_for_storyteller(game) do
    storyteller_id = get_storyteller_id(game)
    storyteller = get_storyteller(game)
    other_players = List.delete(game.order, storyteller_id)

    guesses =
      Enum.map(other_players, fn user_id ->
        game.players[user_id].guess
      end)

    filtered_guesses =
      Enum.filter(guesses, fn guess ->
        guess == storyteller.pick
      end)

    length(filtered_guesses) == 0
  end

  def points_for_correct_guesses(game) do
    storyteller = get_storyteller(game)
    storyteller_id = get_storyteller_id(game)

    updated_points =
      List.delete(game.order, storyteller_id)
      |> Enum.reduce(%{}, fn user_id, acc ->
        player = game.players[user_id]

        updated_player =
          case player.guess == storyteller.pick do
            true ->
              Map.update!(player, :points, &(&1 + 3))

            _ ->
              player
          end

        Map.put(acc, user_id, updated_player)
      end)

    Map.update!(game, :players, &Map.merge(&1, updated_points))
  end

  def pick_to_player_map(game) do
    players = game.players

    Enum.reduce(players, %{}, fn {user_id, player}, acc ->
      Map.put(acc, player.pick, user_id)
    end)
  end

  def points_for_others_guesses(game) do
    storyteller = get_storyteller(game)
    storyteller_id = get_storyteller_id(game)
    storyteller_card = storyteller.pick

    picks = pick_to_player_map(game)

    filtered_players =
      Enum.filter(game.players, fn {user_id, player} ->
        storyteller_id != user_id and player.guess != storyteller_card
      end)

    user_points =
      Enum.reduce(filtered_players, %{}, fn {_, player}, acc ->
        user_to_give_points = picks[player.guess]

        Map.update(acc, user_to_give_points, 3, &(&1 + 3))
      end)

    updated_players =
      Enum.reduce(user_points, game.players, fn {user_id, points}, players ->
        Map.update!(
          players,
          user_id,
          &Map.update!(&1, :points, fn old_points -> old_points + points end)
        )
      end)

    Map.put(game, :players, updated_players)
  end

  def score_storyteller(game) do
    storyteller_id = get_storyteller_id(game)

    points_for_story_teller =
      not (all_vote_for_storyteller(game) or none_vote_for_storyteller(game))

    case points_for_story_teller do
      true ->
        Map.update!(game, :players, fn players ->
          Map.update!(players, storyteller_id, fn storyteller ->
            Map.update!(storyteller, :points, &(&1 + 3))
          end)
        end)

      false ->
        game
    end
  end

  def score_round(game) do
    game
    |> score_storyteller()
    |> points_for_correct_guesses()
    |> points_for_others_guesses()
  end

  def player_names(game) do
    Enum.map(game.players, fn {user_id, player} -> player.name end)
  end

  def start_game(game) do
    game
    |> set_order()
    |> deal()
  end

  def get_picks(game) do
    Enum.map(game.players, fn {user_id, player} ->
      player.pick
    end)
    |> Enum.shuffle()
  end

  def all_guessed(game) do
    storyteller_id = get_storyteller_id(game)

    Enum.filter(game.players, fn {user_id, player} ->
      user_id != storyteller_id
    end)
    |> Enum.all?(fn {user_id, player} ->
      not is_nil(player.guess)
    end)
  end

  def card_to_user_guess(game) do
    players = game.players

    Enum.reduce(players, %{}, fn {user_id, player}, acc ->
      case player.guess do
        nil ->
          acc

        guess ->
          new_map = Map.put_new(acc, guess, [])
          Map.put(new_map, guess, [user_id | Map.get(new_map, guess)])
      end
    end)
  end

  def leaderboard(game) do
    players = game.players

    Enum.reduce(players, %{}, fn {user_id, player}, acc ->
      Map.put(acc, user_id, player.points)
    end)
    |> Enum.sort(fn {_, pointsA}, {_, pointsB} -> pointsA >= pointsB end)
  end

  def next_round(game) do
    number_of_players = length(game.order)
    take_amount = number_of_players
    new_cards = Enum.take(game.deck, take_amount)

    updated_deck = Enum.drop(game.deck, take_amount)

    discards =
      Enum.map(game.players, fn {user_id, player} ->
        player.pick
      end)

    reset_players =
      Enum.map(game.players, fn {user_id, player} ->
        {user_id,
         Map.merge(player, %{
           ready: false,
           pick: nil,
           guess: nil
         })}
      end)

    updated_players =
      Enum.zip(new_cards, reset_players)
      |> Enum.map(fn {card, {user_id, player}} ->
        {user_id, Map.put(player, :hand, [card | player.hand])}
      end)
      |> Enum.into(%{})

    updated_discards = discards ++ game.discard
    updated_state = "STORYTELLER_PICK"

    updated_turn = rem(game.current_turn + 1, number_of_players)

    Map.merge(game, %{
      players: updated_players,
      discard: updated_discards,
      current_turn: updated_turn,
      state: updated_state,
      deck: updated_deck
    })
  end
end
