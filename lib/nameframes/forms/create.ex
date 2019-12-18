defmodule Nameframes.Forms.CreateGame do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :player_name
    field :game_id
  end

  def changeset(create_game, params \\ %{}) do
    create_game
    |> cast(params, [:player_name])
    |> validate_required([:player_name])
    |> put_change(:game_id, Enum.random(1000..9999) |> Integer.to_string())
  end
end
