defmodule Nameframes.Games do
  alias Nameframes.Games.{CreateGame, JoinGame}

  def change_create_game(%CreateGame{} = create_game) do
    CreateGame.changeset(create_game, %{})
  end

  def change_join_game(%JoinGame{} = join_game) do
    JoinGame.changeset(join_game, %{})
  end

  def create_game(attrs \\ %{}) do
    %CreateGame{}
    |> CreateGame.changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def join_game(attrs \\ %{}) do
    %JoinGame{}
    |> JoinGame.changeset(attrs)
    |> Ecto.Changeset.apply_action(:insert)
  end
end
