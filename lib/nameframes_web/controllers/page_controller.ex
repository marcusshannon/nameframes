defmodule NameframesWeb.PageController do
  use NameframesWeb, :controller
  alias Nameframes.Forms
  alias Nameframes.Forms.{CreateGame, JoinGame}

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    changeset = Forms.change_create_game(%CreateGame{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"create_game" => create_game_params}) do
    case Forms.create_game(create_game_params) do
      {:ok, create_game} ->
        game_id = create_game.game_id
        player_id = Ecto.UUID.generate()
        player_name = create_game.player_name

        Nameframes.Store.new(game_id, Nameframes.Games.new_game(player_id, player_name))

        conn
        |> put_session(:player_id, player_id)
        |> put_session(:player_name, player_name)
        |> redirect(to: Routes.live_path(conn, NameframesWeb.GameLive, create_game.game_id))

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  def join(conn, _params) do
    changeset = Forms.change_join_game(%JoinGame{})
    render(conn, "join.html", changeset: changeset)
  end

  def add(conn, %{"join_game" => join_game_params}) do
    case Forms.join_game(join_game_params) do
      {:ok, join_game} ->
        game_id = join_game.game_id
        player_id = Ecto.UUID.generate()
        player_name = join_game.player_name

        case Nameframes.Store.call(game_id, {:join, player_id, player_name}) do
          :ok ->
            conn
            |> put_session(:player_id, player_id)
            |> put_session(:player_name, player_name)
            |> redirect(to: Routes.live_path(conn, NameframesWeb.GameLive, join_game.game_id))

          :error ->
            changeset = Forms.change_join_game(join_game)

            conn
            |> put_flash(:error, "Can't join game")
            |> render("join.html", changeset: changeset)
        end

      {:error, changeset} ->
        render(conn, "join.html", changeset: changeset)
    end
  end
end
