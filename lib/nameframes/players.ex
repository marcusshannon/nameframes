defmodule Nameframes.Players do
  def new_player(player_id, player_name) do
    %{
      id: player_id,
      name: player_name,
      hand: [],
      points: 0,
      pick: nil,
      guess: nil,
      ready: false,
      round_points: 0,
    }
  end

  def prepare_player(player) do
    player
    |> put_in([:pick], nil)
    |> put_in([:guess], nil)
    |> update_in([:hand], &List.delete(&1, player.pick))
  end
end
