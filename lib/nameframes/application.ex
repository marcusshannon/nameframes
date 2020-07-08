defmodule Nameframes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Nameframes.Repo,
      # Start the Telemetry supervisor
      NameframesWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Nameframes.PubSub},
      # Start the endpoint when the application starts
      NameframesWeb.Endpoint,
      # Starts a worker by calling: Nameframes.Worker.start_link(arg)
      # {Nameframes.Worker, arg},
      {DynamicSupervisor, [strategy: :one_for_one, name: Nameframes.Store.Supervisor]},
      {Registry, [keys: :unique, name: Nameframes.Store.Registry]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nameframes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NameframesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
