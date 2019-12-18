defmodule Nameframes.Decks do
  @hand_size 6

  def new_deck() do
    Enum.to_list(1..98)
    |> Enum.shuffle()
  end

  def can_deal?(deck, players_count) do
    length(deck) >= players_count
  end

  def initial_deal(deck, players_count) do
    take_amount = players_count * @hand_size
    to_deal = Enum.take(deck, take_amount) |> Enum.chunk_every(6)
    updated_deck = Enum.drop(deck, take_amount)

    {to_deal, updated_deck}
  end

  def round_deal(deck, players_count) do
    to_deal = Enum.take(deck, players_count)
    updated_deck = Enum.drop(deck, players_count)

    {to_deal, updated_deck}
  end
end
