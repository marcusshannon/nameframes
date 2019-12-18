defmodule Nameframes.Forms.JoinGame do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :player_name
    field :game_id
  end

  def changeset(join_game, params \\ %{}) do
    join_game
    |> cast(params, [:player_name, :game_id])
    |> validate_required([:player_name, :game_id])
  end
end
