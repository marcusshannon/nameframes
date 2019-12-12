defmodule Nameframes.Games.CreateGame do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name
    field :game_id
  end

  def changeset(create_game, params \\ %{}) do
    create_game
    |> cast(params, [:name])
    |> validate_required([:name])
    |> put_change(:game_id, Enum.random(1000..9999) |> Integer.to_string())
  end
end
