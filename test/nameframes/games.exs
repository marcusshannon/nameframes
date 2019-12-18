defmodule GamesTest do
  alias Nameframes.{Games, Players, Decks}

  use ExUnit.Case
  doctest Games

  @player_name_1 "Marcus"
  @player_id_1 "1"

  @player_name_2 "Shannon"
  @player_id_2 "2"

  @player_name_3 "Patrick"
  @player_id_3 "3"

  test "creates a new game" do
  end

  test "player joins" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})

    assert map_size(game.players) == 2
  end

  test "small lobby -> lobby" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})

    assert map_size(game.players) == 3
    assert game.status == :lobby
  end

  test "initial deck and prepare deal" do
    deck = Decks.new_deck()
    {to_deal, updated_deck} = Decks.initial_deal(deck, 6)

    assert length(to_deal) == 6
    assert length(updated_deck) == 62
  end

  test "deal to players" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})

    game = Games.initial_deal(game)

    assert length(game.players[@player_id_1].hand) == 6
    assert length(game.deck) == 80
  end

  test "random order" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})

    game = Games.set_order(game)

    assert length(game.order) == 3
  end

  test "start game" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})

    {:ok, game} = Games.event(game, {:start, @player_id_1})

    assert game.status == :storyteller_pick
  end

  test "storyteller pick" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})
    {:ok, game} = Games.event(game, {:start, @player_id_1})

    storyteller_id = hd(game.order)
    storyteller_card = hd(game.players[storyteller_id].hand)

    {:ok, game} = Games.event(game, {:pick, storyteller_id, storyteller_card})

    assert game.players[storyteller_id].pick == storyteller_card
    assert game.status == :others_pick
  end

  test "others pick" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})
    {:ok, game} = Games.event(game, {:start, @player_id_1})

    storyteller_id = hd(game.order)
    storyteller_card = hd(game.players[storyteller_id].hand)

    other_1_id = Enum.at(game.order, 1)
    other_1_card = Enum.at(game.players[other_1_id].hand, 0)

    other_2_id = Enum.at(game.order, 2)
    other_2_card = Enum.at(game.players[other_2_id].hand, 0)

    {:ok, game} = Games.event(game, {:pick, storyteller_id, storyteller_card})
    {:ok, game} = Games.event(game, {:pick, other_1_id, other_1_card})

    assert game.status == :others_pick

    {:ok, game} = Games.event(game, {:pick, other_2_id, other_2_card})

    assert game.status == :others_guess
  end

  test "others guess" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})
    {:ok, game} = Games.event(game, {:start, @player_id_1})

    storyteller_id = hd(game.order)
    storyteller_card = hd(game.players[storyteller_id].hand)

    other_1_id = Enum.at(game.order, 1)
    other_1_card = Enum.at(game.players[other_1_id].hand, 0)

    other_2_id = Enum.at(game.order, 2)
    other_2_card = Enum.at(game.players[other_2_id].hand, 0)

    {:ok, game} = Games.event(game, {:pick, storyteller_id, storyteller_card})
    {:ok, game} = Games.event(game, {:pick, other_1_id, other_1_card})
    {:ok, game} = Games.event(game, {:pick, other_2_id, other_2_card})
    {:ok, game} = Games.event(game, {:guess, other_1_id, storyteller_card})
    Games.event(game, {:guess, other_2_id, other_1_card})
  end

  test "scoring all storyteller" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})
    {:ok, game} = Games.event(game, {:start, @player_id_1})

    storyteller_id = hd(game.order)
    storyteller_card = hd(game.players[storyteller_id].hand)

    other_1_id = Enum.at(game.order, 1)
    other_1_card = Enum.at(game.players[other_1_id].hand, 0)

    other_2_id = Enum.at(game.order, 2)
    other_2_card = Enum.at(game.players[other_2_id].hand, 0)

    {:ok, game} = Games.event(game, {:pick, storyteller_id, storyteller_card})
    {:ok, game} = Games.event(game, {:pick, other_1_id, other_1_card})
    {:ok, game} = Games.event(game, {:pick, other_2_id, other_2_card})
    {:ok, game} = Games.event(game, {:guess, other_1_id, storyteller_card})
    {:ok, game} = Games.event(game, {:guess, other_2_id, storyteller_card})

    assert game.players[storyteller_id].points === 0
    assert game.players[other_1_id].points === 2
    assert game.players[other_2_id].points === 2
  end

  test "scoring mixed" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})
    {:ok, game} = Games.event(game, {:start, @player_id_1})

    storyteller_id = hd(game.order)
    storyteller_card = hd(game.players[storyteller_id].hand)

    other_1_id = Enum.at(game.order, 1)
    other_1_card = Enum.at(game.players[other_1_id].hand, 0)

    other_2_id = Enum.at(game.order, 2)
    other_2_card = Enum.at(game.players[other_2_id].hand, 0)

    {:ok, game} = Games.event(game, {:pick, storyteller_id, storyteller_card})
    {:ok, game} = Games.event(game, {:pick, other_1_id, other_1_card})
    {:ok, game} = Games.event(game, {:pick, other_2_id, other_2_card})
    {:ok, game} = Games.event(game, {:guess, other_1_id, storyteller_card})
    {:ok, game} = Games.event(game, {:guess, other_2_id, other_1_card})

    assert game.players[storyteller_id].points === 3
    assert game.players[other_1_id].points === 4
    assert game.players[other_2_id].points === 0
  end

  test "scoring none storyteller" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})
    {:ok, game} = Games.event(game, {:start, @player_id_1})

    storyteller_id = hd(game.order)
    storyteller_card = hd(game.players[storyteller_id].hand)

    other_1_id = Enum.at(game.order, 1)
    other_1_card = Enum.at(game.players[other_1_id].hand, 0)

    other_2_id = Enum.at(game.order, 2)
    other_2_card = Enum.at(game.players[other_2_id].hand, 0)

    {:ok, game} = Games.event(game, {:pick, storyteller_id, storyteller_card})
    {:ok, game} = Games.event(game, {:pick, other_1_id, other_1_card})
    {:ok, game} = Games.event(game, {:pick, other_2_id, other_2_card})
    {:ok, game} = Games.event(game, {:guess, other_1_id, other_2_card})
    {:ok, game} = Games.event(game, {:guess, other_2_id, other_1_card})

    assert game.players[storyteller_id].points === 0
    assert game.players[other_1_id].points === 3
    assert game.players[other_2_id].points === 3
  end

  test "round reset" do
    game = Games.new_game(@player_id_1, @player_name_1)
    {:ok, game} = Games.event(game, {:join, @player_id_2, @player_name_2})
    {:ok, game} = Games.event(game, {:join, @player_id_3, @player_name_3})
    {:ok, game} = Games.event(game, {:start, @player_id_1})

    storyteller_id = hd(game.order)
    storyteller_card = hd(game.players[storyteller_id].hand)

    other_1_id = Enum.at(game.order, 1)
    other_1_card = Enum.at(game.players[other_1_id].hand, 0)

    other_2_id = Enum.at(game.order, 2)
    other_2_card = Enum.at(game.players[other_2_id].hand, 0)

    {:ok, game} = Games.event(game, {:pick, storyteller_id, storyteller_card})
    {:ok, game} = Games.event(game, {:pick, other_1_id, other_1_card})
    {:ok, game} = Games.event(game, {:pick, other_2_id, other_2_card})
    {:ok, game} = Games.event(game, {:guess, other_1_id, other_2_card})
    {:ok, game} = Games.event(game, {:guess, other_2_id, other_1_card})

    {:ok, game} = Games.event(game, {:ready, @player_id_1})
    {:ok, game} = Games.event(game, {:ready, @player_id_2})
    {:ok, game} = Games.event(game, {:ready, @player_id_3})
  end
end
