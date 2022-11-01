defmodule Gruppie.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Gruppie.Repo,
      # Start the Telemetry supervisor
      GruppieWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Gruppie.PubSub},
      # Start the Endpoint (http/https)
      GruppieWeb.Endpoint,
       # Start a worker by calling: Gruppie.Worker.start_link(arg)
      # {Gruppie.Worker, arg}
      #mongo connection
      {Mongo, [name: :mongo, database: "gruppie", pool_size: 2]}

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gruppie.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GruppieWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
