defmodule Nameframes.Games do
  alias Nameframes.{Decks, Players}

  # helpers
  def leaderboard(game) do
    game.players
    |> Enum.map(fn {_player_id, player} ->
      {player.name, player.points}
    end)
    |> Enum.sort(fn {_player_idA, points_A}, {_player_idB, points_B} ->
      points_A > points_B
    end)
  end

  def picks_player(game) do
    game.players
    |> Enum.reduce(%{}, fn {player_id, player}, acc ->
      put_in(acc, [player.pick], player_id)
    end)
  end

  def player_guesses(game) do
    storyteller_id = get_storyteller_id(game)
    picks_player = picks_player(game)

    base =
      game.display_order
      |> Enum.reduce(%{}, fn player_id, acc ->
        put_in(acc, [player_id], [])
      end)

    base
    |> Enum.reject(fn {player_id, _guess_list} ->
      player_id === storyteller_id
    end)
    |> Enum.reduce(base, fn {player_id, _guess_list}, acc ->
      player_guessed_for = picks_player[game.players[player_id].guess]
      update_in(acc, [player_guessed_for], &[player_id | &1])
    end)
  end

  def storyteller_guesses(game) do
    storyteller_id = get_storyteller_id(game)
    player_guesses = player_guesses(game)

    player_guesses[storyteller_id]
    |> Enum.map(fn player_id ->
      %{name: game.players[player_id].name}
    end)
  end

  def guesses_for_player(game, player_id) do
    player_guesses = player_guesses(game)

    player_guesses[player_id]
    |> Enum.map(fn id ->
      %{name: game.players[id].name}
    end)
  end

  def display_others(game) do
    storyteller_id = get_storyteller_id(game)
    player_guesses = player_guesses(game)

    game.display_order
    |> Enum.reject(fn id ->
      id === storyteller_id
    end)
    |> Enum.map(fn id ->
      %{
        name: game.players[id].name,
        round_points: game.players[id].round_points,
        pick: game.players[id].pick,
        guess_list:
          Enum.map(player_guesses[id], fn id ->
            %{name: game.players[id].name}
          end)
      }
    end)
  end

  def show_guessable_cards(game, player_id) do
    game.display_order
    |> Enum.reject(fn id ->
      id === player_id
    end)
    |> Enum.map(fn id ->
      game.players[id].pick
    end)
  end

  def has_guessed?(game, player_id) do
    not is_nil(game.players[player_id].guess)
  end

  def has_picked?(game, player_id) do
    not is_nil(game.players[player_id].pick)
  end

  def player_names(game) do
    Enum.map(game.players, fn {_player_id, player} ->
      player.name
    end)
  end

  def is_host?(game, player_id) do
    game.host === player_id
  end

  def is_storyteller?(game, player_id) do
    get_storyteller_id(game) === player_id
  end

  def all_ready?(game) do
    Enum.all?(game.players, fn {_player_id, player} ->
      player.ready
    end)
  end

  def guessed_storyteller_points(game) do
    storyteller_id = get_storyteller_id(game)
    storyteller_card = game.players[storyteller_id].pick

    game.players
    |> Enum.reject(fn {player_id, _player} ->
      player_id === storyteller_id
    end)
    |> Enum.map(fn {player_id, player} ->
      case player.guess === storyteller_card do
        true ->
          {player_id, 3}

        false ->
          {player_id, 0}
      end
    end)
    |> Enum.into(%{})
  end

  def others_points(game) do
    storyteller_id = get_storyteller_id(game)
    storyteller_card = game.players[storyteller_id].pick

    others =
      game.players
      |> Enum.reject(fn {player_id, _player} ->
        player_id === storyteller_id
      end)

    picks =
      others
      |> Enum.map(fn {_player_id, player} ->
        {player.pick, 0}
      end)
      |> Enum.into(%{})

    pick_points =
      others
      |> Enum.reject(fn {_player_id, player} -> player.guess === storyteller_card end)
      |> Enum.reduce(picks, fn {_player_id, player}, acc ->
        update_in(acc, [player.guess], &(&1 + 1))
      end)

    others
    |> Enum.map(fn {player_id, player} ->
      {player_id, pick_points[player.pick]}
    end)
    |> Enum.into(%{})
  end

  def all_or_none_guessed_storyteller_card?(game) do
    storyteller_id = get_storyteller_id(game)
    stoyteller_card = game.players[storyteller_id].pick

    others =
      game.players
      |> Enum.reject(fn {player_id, _player} ->
        player_id === storyteller_id
      end)

    all_guessed_storyteller_card =
      others
      |> Enum.all?(fn {_player_id, player} ->
        player.guess === stoyteller_card
      end)

    none_guessed_storteller_card =
      others
      |> Enum.all?(fn {_player_id, player} ->
        player.guess !== stoyteller_card
      end)

    all_guessed_storyteller_card or none_guessed_storteller_card
  end

  def player_points(game) do
    storyteller_id = get_storyteller_id(game)
    all_or_none_guessed_storyteller_card = all_or_none_guessed_storyteller_card?(game)
    base_points = others_points(game)
    guessed_storyteller_points = guessed_storyteller_points(game)

    case all_or_none_guessed_storyteller_card do
      true ->
        base_points
        |> Enum.map(fn {player_id, points} ->
          {player_id, points + 2}
        end)
        |> Enum.into(%{})
        |> put_in([storyteller_id], 0)

      false ->
        base_points
        |> Map.merge(guessed_storyteller_points, fn _k, v1, v2 -> v1 + v2 end)
        |> put_in([storyteller_id], 3)
    end
  end

  def score(game) do
    storyteller_id = get_storyteller_id(game)
    all_or_none_guessed_storyteller_card = all_or_none_guessed_storyteller_card?(game)
    base_points = others_points(game)
    guessed_storyteller_points = guessed_storyteller_points(game)

    player_points =
      case all_or_none_guessed_storyteller_card do
        true ->
          base_points
          |> Enum.map(fn {player_id, points} ->
            {player_id, points + 2}
          end)
          |> Enum.into(%{})
          |> put_in([storyteller_id], 0)

        false ->
          base_points
          |> Map.merge(guessed_storyteller_points, fn _k, v1, v2 -> v1 + v2 end)
          |> put_in([storyteller_id], 3)
      end

    updated_players =
      game.players
      |> Enum.map(fn {player_id, player} ->
        {player_id,
         player
         |> update_in([:points], &(&1 + player_points[player_id]))
         |> put_in([:round_points], player_points[player_id])}
      end)
      |> Enum.into(%{})

    put_in(game, [:players], updated_players)
  end

  def prepare_next_round(game) do
    player_count = map_size(game.players)
    can_deal = Decks.can_deal?(game.deck, player_count)

    discards =
      game.discards ++
        (game.players
         |> Enum.map(fn {_player_id, player} -> player.pick end))

    {updated_deck, updated_discards} =
      case can_deal do
        true ->
          {game.deck, discards}

        false ->
          {game.deck ++ Enum.shuffle(discards), []}
      end

    {to_deal, updated_deck} = Decks.round_deal(updated_deck, player_count)

    updated_players =
      Enum.zip(to_deal, game.players)
      |> Enum.map(fn {new_card, {player_id, player}} ->
        updated_player =
          player
          |> update_in([:hand], &[new_card | List.delete(&1, player.pick)])
          |> put_in([:pick], nil)
          |> put_in([:guess], nil)
          |> put_in([:ready], false)
          |> put_in([:round_points], 0)

        {player_id, updated_player}
      end)
      |> Enum.into(%{})

    game
    |> put_in([:status], :storyteller_pick)
    |> update_in([:turn], &rem(&1 + 1, player_count))
    |> put_in([:discards], updated_discards)
    |> put_in([:deck], updated_deck)
    |> put_in([:players], updated_players)
    |> put_in([:display_order], Enum.shuffle(game.order))
  end

  def guessable_cards(game, player_id) do
    game.players
    |> Enum.reject(fn {id, _player} ->
      id === player_id
    end)
    |> Enum.map(fn {_player_id, player} ->
      player.pick
    end)
  end

  def all_guessed?(game) do
    storyteller_id = get_storyteller_id(game)

    game.players
    |> Enum.reject(fn {player_id, _player} ->
      player_id == storyteller_id
    end)
    |> Enum.all?(fn {_player_id, player} ->
      not is_nil(player.guess)
    end)
  end

  def all_picked?(game) do
    storyteller_id = get_storyteller_id(game)

    game.players
    |> Enum.reject(fn {player_id, _player} ->
      player_id == storyteller_id
    end)
    |> Enum.all?(fn {_player_id, player} ->
      not is_nil(player.pick)
    end)
  end

  def get_storyteller_id(game) do
    Enum.at(game.order, game.turn)
  end

  def new_game(player_id, player_name) do
    %{
      status: :lobby_small,
      host: player_id,
      players: %{player_id => Players.new_player(player_id, player_name)},
      deck: Decks.new_deck(),
      discards: [],
      turn: 0,
      order: [],
      display_order: []
    }
  end

  def initial_deal(game) do
    {to_deal, updated_deck} = Decks.initial_deal(game.deck, map_size(game.players))

    updated_players =
      Enum.zip(to_deal, game.players)
      |> Enum.map(fn {hand, {player_id, player}} ->
        {player_id, put_in(player, [:hand], hand)}
      end)
      |> Enum.into(%{})

    game
    |> put_in([:players], updated_players)
    |> put_in([:deck], updated_deck)
  end

  def set_order(game) do
    order =
      Enum.map(game.players, fn {player_id, _player} ->
        player_id
      end)
      |> Enum.shuffle()

    game
    |> put_in([:order], order)
    |> put_in([:display_order], Enum.shuffle(order))
  end

  # Events

  def event(%{status: :lobby_small} = game, {:join, player_id, player_name}) do
    updated_game = put_in(game, [:players, player_id], Players.new_player(player_id, player_name))
    number_of_players = map_size(updated_game.players)

    case number_of_players > 3 do
      true ->
        {:ok, put_in(updated_game, [:status], :lobby)}

      false ->
        {:ok, updated_game}
    end
  end

  def event(%{status: :lobby} = game, {:join, player_id, player_name}) do
    updated_game = put_in(game, [:players, player_id], Players.new_player(player_id, player_name))
    {:ok, updated_game}
  end

  def event(%{status: :lobby} = game, {:start, player_id}) do
    case player_id == game.host do
      true ->
        {:ok,
         game
         |> set_order
         |> initial_deal
         |> put_in([:status], :storyteller_pick)}

      false ->
        {:error}
    end
  end

  def event(%{status: :storyteller_pick} = game, {:pick, player_id, card_id}) do
    is_storyteller? = get_storyteller_id(game) == player_id
    has_card? = Enum.member?(game.players[player_id].hand, card_id)

    case is_storyteller? and has_card? do
      true ->
        updated_game =
          game
          |> put_in([:players, player_id, :pick], card_id)
          |> put_in([:status], :others_pick)

        {:ok, updated_game}

      false ->
        {:error}
    end
  end

  def event(%{status: :others_pick} = game, {:pick, player_id, card_id}) do
    is_storyteller? = get_storyteller_id(game) == player_id
    has_card? = Enum.member?(game.players[player_id].hand, card_id)

    case not is_storyteller? and has_card? do
      true ->
        updated_game =
          game
          |> put_in([:players, player_id, :pick], card_id)

        case all_picked?(updated_game) do
          true ->
            {:ok, put_in(updated_game, [:status], :others_guess)}

          false ->
            {:ok, updated_game}
        end

      false ->
        {:error}
    end
  end

  def event(%{status: :others_guess} = game, {:guess, player_id, card_id}) do
    is_storyteller? = get_storyteller_id(game) === player_id
    valid_guess? = Enum.member?(guessable_cards(game, player_id), card_id)

    case not is_storyteller? and valid_guess? do
      true ->
        updated_game =
          game
          |> put_in([:players, player_id, :guess], card_id)

        case all_guessed?(updated_game) do
          true ->
            updated_game =
              updated_game
              |> score()
              |> put_in([:status], :results)

            {:ok, updated_game}

          false ->
            {:ok, updated_game}
        end

      false ->
        {:error}
    end
  end

  def event(%{status: :results} = game, {:ready, player_id}) do
    updated_game =
      game
      |> put_in([:players, player_id, :ready], true)

    case all_ready?(updated_game) do
      true ->
        {:ok,
         updated_game
         |> put_in([:status], :storyteller_pick)
         |> prepare_next_round}

      false ->
        {:ok, updated_game}
    end
  end

  def event(_, _) do
    {:error}
  end
end
