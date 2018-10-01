defmodule Timber.PhoenixTest do
  # This test case has to be asynchronous since it modifies and depends on
  # the application environment which is global
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog


  require Logger

  setup do
    on_exit(fn ->
      # Delete environment keys used
      Application.delete_env(:timber_phoenix, :parsed_controller_actions_blacklist)
      Application.delete_env(:timber_phoenix, :controller_actions_blacklist)
    end)

    :ok
  end

  describe "Timber.Integrations.Timber.Phoenix.get_unparsed_blacklist/0" do
    test "fetches the unparsed blacklist from the Application environment" do
      blacklist = [
        {A, :action},
        {B, :action}
      ]

      Application.put_env(:timber_phoenix, :controller_actions_blacklist, blacklist)

      assert [{A, :action}, {B, :action}] = Timber.Phoenix.get_unparsed_blacklist()
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.parse_blacklist/1" do
    test "parses blacklist" do
      unparsed_blacklist = [
        {A, :action},
        {B, :action}
      ]

      parsed_blacklist = Timber.Phoenix.parse_blacklist(unparsed_blacklist)

      assert MapSet.member?(parsed_blacklist, {A, :action})
      assert MapSet.member?(parsed_blacklist, {B, :action})
      refute MapSet.member?(parsed_blacklist, {Controller, :action})
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.add_controller_action_to_blacklist/2" do
    test "adds controller action to the blacklist" do
      Timber.Phoenix.put_parsed_blacklist(
        MapSet.new([
          {A, :action},
          {B, :action}
        ])
      )

      Timber.Phoenix.add_controller_action_to_blacklist(Controller, :action)
      blacklist = Timber.Phoenix.get_parsed_blacklist()

      assert Timber.Phoenix.controller_action_blacklisted?({A, :action}, blacklist)
      assert Timber.Phoenix.controller_action_blacklisted?({B, :action}, blacklist)

      assert Timber.Phoenix.controller_action_blacklisted?(
               {Controller, :action},
               blacklist
             )
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.remove_controller_action_from_blacklist/2" do
    test "removes controller action from blacklist" do
      Timber.Phoenix.put_parsed_blacklist(
        MapSet.new([
          {A, :action},
          {B, :action}
        ])
      )

      Timber.Phoenix.remove_controller_action_from_blacklist(B, :action)

      blacklist = Timber.Phoenix.get_parsed_blacklist()

      assert Timber.Phoenix.controller_action_blacklisted?({A, :action}, blacklist)
      refute Timber.Phoenix.controller_action_blacklisted?({B, :action}, blacklist)
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.get_parsed_blacklist/0" do
    test "retrieves empty MapSet when blacklist is not in application environment" do
      :ok = Application.delete_env(:timber_phoenix, :parsed_controller_actions_blacklist)
      blacklist = Timber.Phoenix.get_parsed_blacklist()
      assert match?(%MapSet{}, blacklist)
    end

    test "retrieves the blacklist from the application environment" do
      blacklist =
        MapSet.new([
          {A, :action},
          {B, :action}
        ])

      :ok = Application.put_env(:timber_phoenix, :parsed_controller_actions_blacklist, blacklist)

      ^blacklist = Timber.Phoenix.get_parsed_blacklist()
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.put_parsed_blacklist/1" do
    test "puts the blacklist in the application environment" do
      blacklist =
        MapSet.new([
          {A, :action},
          {B, :action}
        ])

      Timber.Phoenix.put_parsed_blacklist(blacklist)

      ^blacklist = Application.get_env(:timber_phoenix, :parsed_controller_actions_blacklist, [])
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.phoenix_channel_join/3" do
    test "logs phoenix_channel_join as configured by the channel" do
      log =
        capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}

          Timber.Phoenix.phoenix_channel_join(:start, %{}, %{
            socket: socket,
            params: %{key: "val"}
          })
        end)

      assert log =~ "Joined channel channel with \"topic\""
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.phoenix_channel_receive/3" do
    test "logs phoenix_channel_receive as configured by the channel" do
      log =
        capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}

          Timber.Phoenix.phoenix_channel_receive(:start, %{}, %{
            socket: socket,
            event: "e",
            params: %{}
          })
        end)

      assert log =~ "Received e on \"topic\" to channel"
    end

    test "accepts a message where the params is a keyword list" do
      log =
        capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          params = [name: "Geoffrey"]

          metadata = %{
            socket: socket,
            event: "e",
            params: params
          }

          Timber.Phoenix.phoenix_channel_receive(:start, %{}, metadata)
        end)

      assert log =~ ~s/Received e on "topic" to channel/
    end

    test "accepts a message where the params is a non-Keyword list" do
      log =
        capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          params = ["a", "b"]

          metadata = %{
            socket: socket,
            event: "e",
            params: params
          }

          Timber.Phoenix.phoenix_channel_receive(:start, %{}, metadata)
        end)

      assert log =~ ~s/Received e on "topic" to channel/
    end

    test "accepts a message where the params is a string" do
      log =
        capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          params = "61cf02ad-9509-48be-9b88-edf5e85219fe"

          metadata = %{
            socket: socket,
            event: "e",
            params: params
          }

          Timber.Phoenix.phoenix_channel_receive(:start, %{}, metadata)
        end)

      assert log =~ ~s/Received e on "topic" to channel/
    end

    test "accept a message where the params ia numeric value" do
      log =
        capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          params = 3.14

          metadata = %{
            socket: socket,
            event: "e",
            params: params
          }

          Timber.Phoenix.phoenix_channel_receive(:start, %{}, metadata)
        end)

      assert log =~ ~s/Received e on "topic" to channel/
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.phoenix_controller_call/3" do
    test "logs phoenix controller calls" do
      controller = Controller
      action = :action

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_private(:phoenix_controller, controller)
        |> Plug.Conn.put_private(:phoenix_action, action)

      log =
        capture_log(fn ->
          Timber.Phoenix.phoenix_controller_call(:start, %{}, %{conn: conn})
        end)

      assert log =~ "Processing with Controller.action/2"
    end

    test "does not log controller calls if the controller/action pair is in the black list" do
      controller = Controller
      action = :action

      Timber.Phoenix.add_controller_action_to_blacklist(controller, action)

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_private(:phoenix_controller, controller)
        |> Plug.Conn.put_private(:phoenix_action, action)

      log =
        capture_log(fn ->
          Timber.Phoenix.phoenix_controller_call(:start, %{}, %{conn: conn})
        end)

      assert log == ""
    end
  end

  describe "Timber.Integrations.Timber.Phoenix.phoenix_controller_render/3" do
    test ":start returns the log level and template name by default" do
      controller = Controller
      action = :action
      template_name = "index.html"

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_private(:phoenix_controller, controller)
        |> Plug.Conn.put_private(:phoenix_action, action)

      assert {:ok, :info, ^template_name} =
               Timber.Phoenix.phoenix_controller_render(:start, %{}, %{
                 template: template_name,
                 conn: conn
               })
    end

    test ":start returns true when the controller/action is not available" do
      # This test situation occurs when the route cannot be matched, for example
      template_name = "404.html"

      conn = Phoenix.ConnTest.build_conn()

      assert {:ok, :info, ^template_name} =
               Timber.Phoenix.phoenix_controller_render(:start, %{}, %{
                 template: template_name,
                 conn: conn
               })
    end

    test ":start returns false when the controller/action is blacklisted" do
      controller = Controller
      action = :action
      template_name = "index.html"

      Timber.Phoenix.add_controller_action_to_blacklist(controller, action)

      conn =
        Phoenix.ConnTest.build_conn()
        |> Plug.Conn.put_private(:phoenix_controller, controller)
        |> Plug.Conn.put_private(:phoenix_action, action)

      assert false ==
               Timber.Phoenix.phoenix_controller_render(:start, %{}, %{
                 template: template_name,
                 conn: conn
               })
    end

    test ":start returns true when a template name is given but no connection" do
      # This test situation occurs when the route cannot be matched, for example
      template_name = "404.html"

      assert {:ok, :info, ^template_name} =
               Timber.Phoenix.phoenix_controller_render(:start, %{}, %{
                 template: template_name
               })
    end

    test ":start returns :ok when an unsupported map is passed" do
      assert :ok = Timber.Phoenix.phoenix_controller_render(:start, %{}, %{})
    end

    test ":stop does not log anything when the third param is :ok" do
      log =
        capture_log(fn ->
          Timber.Phoenix.phoenix_controller_render(:stop, %{}, :ok)
        end)

      assert log == ""
    end

    test ":stop does not log anything when the third param is false" do
      log =
        capture_log(fn ->
          Timber.Phoenix.phoenix_controller_render(:stop, %{}, false)
        end)

      assert log == ""
    end

    test ":stop logs the render time when it is present" do
      template_name = "index.html"
      log_level = :info

      log =
        capture_log(fn ->
          Timber.Phoenix.phoenix_controller_render(
            :stop,
            0,
            {:ok, log_level, template_name}
          )
        end)

      assert log =~ "Rendered \"index.html\" in 0.0ms"
    end
  end
end
