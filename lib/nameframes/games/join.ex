defmodule Nameframes.Games.JoinGame do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name
    field :game_id
  end

  def changeset(join_game, params \\ %{}) do
    join_game
    |> cast(params, [:name, :game_id])
    |> validate_required([:name, :game_id])
  end
end
