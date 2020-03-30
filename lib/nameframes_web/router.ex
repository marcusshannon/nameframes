defmodule NameframesWeb.Router do
  use NameframesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug NameframesWeb.Plugs.Fingerprint
    plug Phoenix.LiveView.Flash
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NameframesWeb do
    pipe_through :browser

    get "/", PageController, :index

    get "/games/new", PageController, :new
    post "/games/create", PageController, :create

    get "/games/join", PageController, :join
    post "/games/join", PageController, :add

    get "/games/:id", PageController, :game
  end

  # Other scopes may use custom stacks.
  # scope "/api", NameframesWeb do
  #   pipe_through :api
  # end
end
