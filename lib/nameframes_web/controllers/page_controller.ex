defmodule NameframesWeb.PageController do
  use NameframesWeb, :controller
  alias Nameframes.Games
  alias Nameframes.Games.{CreateGame, JoinGame}

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    changeset = Games.change_create_game(%CreateGame{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"create_game" => create_game_params}) do
    case Games.create_game(create_game_params) do
      {:ok, create_game} ->
        game_id = create_game.game_id

        user_id = Ecto.UUID.generate()
        user = %{id: user_id, name: create_game.name}
        Nameframes.Store.new(create_game.game_id, Nameframes.Game.new_game(user))

        conn
        |> put_session(:user_id, user_id)
        |> put_session(:user_name, create_game.name)
        |> redirect(to: Routes.live_path(conn, NameframesWeb.GameLive, create_game.game_id))

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  def join(conn, _params) do
    changeset = Games.change_join_game(%JoinGame{})
    render(conn, "join.html", changeset: changeset)
  end

  def add(conn, %{"join_game" => join_game_params}) do
    case Games.join_game(join_game_params) do
      {:ok, join_game} ->
        user_id = Ecto.UUID.generate()
        game_id = join_game.game_id
        user = %{id: user_id, name: join_game.name}
        Nameframes.Store.cast(game_id, {:join, user})

        conn
        |> put_session(:user_id, user_id)
        |> put_session(:user_name, join_game.name)
        |> redirect(to: Routes.live_path(conn, NameframesWeb.GameLive, join_game.game_id))

      {:error, changeset} ->
        render(conn, "join.html", changeset: changeset)
    end
  end
end
