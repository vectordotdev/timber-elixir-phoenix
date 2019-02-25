# 🌲 Timber integration for Phoenix

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber_phoenix.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber_phoenix)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber_phoenix/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir-phoenix.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir-phoenix)

The Timber Phoenix library provides enhanced logging for your Phoenix-based application.

## Installation

1. Ensure that you have both `:timber` (version 3.0.0 or later) and `:timber_phoenix` listed
as dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:timber, "~> 3.1"},
        {:timber_phoenix, "~> 1.0"}
      ]
    end
    ```

2. Run `mix deps.get` to get the dependencies.

3. You'll need to add a configuration line for every Phoenix endpoint. For example,
if you have the application `:my_app` and the Phoenix endpoint `MyApp.Endpoint`,
the configuration in `config/config.exs` would look like this:

    ```elixir
    use Mix.Config

    config :my_app, MyApp.Endpoint,
      # ...,
      instrumenters: [Timber.Phoenix],
    ```

For more information, see the documentation for the
[Timber.Phoenix](https://hexdocs.pm/timber_phoenix/Timber.Phoenix.html) module.

### Notes for Umbrella Applications

When integrating Timber with Phoenix for an umbrella application, the
`:timber_phoenix` library needs to be a dependency for every application that
defines an Phoenix endpoint.

## License

This project is licensed under the ISC License - see [LICENSE] for more details.
