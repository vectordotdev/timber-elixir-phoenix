defmodule Timber.Phoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Timber.Phoenix.Worker.start_link(arg)
      # {Timber.Phoenix.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Timber.Phoenix.Supervisor]

    transform_deprecated_configuration()
    Supervisor.start_link(children, opts)
  end

  defp transform_deprecated_configuration do
    case Application.fetch_env(:timber_phoenix, :controller_actions_blacklist) do
      {:ok, value} ->
        new_config = """
        config :timber_phoenix, parsed_controller_actions_blacklist: MapSet.new(
          #{inspect(value)}
        )
        """

        IO.warn(
          ":controller_actions_blacklist is deprecated. Please place the blacklist " <>
            "in a MapSet under the :parsed_controller_actions_blacklist key. Config should be:\n\n" <>
            new_config
        )

        Timber.Phoenix.put_parsed_blacklist(MapSet.new(value))

        :ok

      :error ->
        :ok
    end
  end
end
