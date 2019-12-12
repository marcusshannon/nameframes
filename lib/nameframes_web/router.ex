defmodule NameframesWeb.Router do
  use NameframesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Phoenix.LiveView.Flash
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NameframesWeb do
    pipe_through :browser

    live "/", IndexLive
    get "/games/new", PageController, :new
    post "/games/create", PageController, :create
    get "/games/join", PageController, :join
    post "/games/join", PageController, :add
    live "/games/:id", GameLive, session: [:user_id, :user_name]
  end

  # Other scopes may use custom stacks.
  # scope "/api", NameframesWeb do
  #   pipe_through :api
  # end
end
