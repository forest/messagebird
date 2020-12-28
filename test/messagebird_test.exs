defmodule MessagebirdTest do
  use ExUnit.Case, async: true
  doctest Messagebird

  setup do
    bypass = Bypass.open()
    config = bypass |> base_url() |> api_config()

    {:ok, bypass: bypass, api_config: config}
  end

  describe "start_link/1" do
    test "raises if :name is not provided" do
      assert_raise(ArgumentError, ~r/must supply a name/, fn ->
        Messagebird.start_link([])
      end)
    end
  end

  describe "check configuration" do
    test "raises when invalid api configuration is provided" do
      assert_raise(
        ArgumentError,
        ~r/valid options are: \[:base_url, :access_key, :backend\]/,
        fn ->
          TestMessagebirdClient.send_text_message([bad: 5], "recipient", "message", [])
        end
      )

      assert_raise(ArgumentError, ~r/expected :access_key to be a string/, fn ->
        TestMessagebirdClient.send_text_message(
          [base_url: "test", access_key: 5],
          "recipient",
          "message",
          []
        )
      end)
    end
  end

  describe "send sms message" do
    test "successful post request, with basic auth header", %{
      bypass: bypass,
      api_config: config
    } do
      start_supervised!({TestMessagebirdClient, []})

      test_response = build_response()

      Bypass.expect_once(bypass, "POST", "/messages", fn conn ->
        assert {_, "application/json"} =
                 Enum.find(conn.req_headers, fn
                   {"accept", _} -> true
                   _ -> false
                 end)

        assert {_, "AccessKey " <> access_key} =
                 Enum.find(conn.req_headers, fn
                   {"authorization", _} -> true
                   _ -> false
                 end)

        assert "test" = access_key

        Plug.Conn.send_resp(conn, 201, Jason.encode!(test_response))
      end)

      assert {:ok, got_response} =
               TestMessagebirdClient.send_text_message(config, "recipient", "message",
                 originator: "TEST"
               )

      assert test_response == got_response
    end
  end

  describe "in-memory backend" do
    setup %{api_config: config} do
      config = Keyword.put(config, :backend, Messagebird.Backend.InMemory)

      {:ok, api_config: config}
    end

    test "send_message", %{api_config: config} do
      start_supervised!({TestMessagebirdClient, []})

      assert {:ok, got_response} =
               TestMessagebirdClient.send_text_message(config, "recipient", "message",
                 originator: "TEST"
               )

      assert %{
               body: "message",
               datacoding: "plain",
               index: 0,
               originator: "TEST",
               recipients: "recipient"
             } == got_response
    end

    test "list_sent_messages", %{api_config: config} do
      start_supervised!({TestMessagebirdClient, []})

      assert {:ok, _} =
               TestMessagebirdClient.send_text_message(config, "recipient #1", "message #1",
                 originator: "TEST"
               )

      assert {:ok, _} =
               TestMessagebirdClient.send_text_message(config, "recipient #2", "message #2",
                 originator: "TEST"
               )

      assert [
               %{
                 body: "message #2",
                 datacoding: "plain",
                 index: 1,
                 originator: "TEST",
                 recipients: "recipient #2"
               },
               %{
                 body: "message #1",
                 datacoding: "plain",
                 index: 0,
                 originator: "TEST",
                 recipients: "recipient #1"
               }
             ] == Messagebird.Backend.InMemory.list_sent_messages()
    end
  end

  defp api_config(base_url),
    do: [base_url: base_url, access_key: "test"]

  defp base_url(%{port: port}), do: "http://localhost:#{port}"

  defp build_response do
    %{
      "id" => "e8077d803532c0b5937c639b60216938",
      "href" => "https => //rest.messagebird.com/messages/e8077d803532c0b5937c639b60216938",
      "direction" => "mt",
      "type" => "sms",
      "originator" => "TEST",
      "body" => "This is a test message",
      "datacoding" => "plain",
      "mclass" => 1,
      "createdDatetime" => "2016-05-03T14 => 26 => 57+00 => 00",
      "recipients" => %{
        "totalCount" => 1,
        "totalSentCount" => 1,
        "totalDeliveredCount" => 0,
        "totalDeliveryFailedCount" => 0,
        "items" => [
          %{
            "recipient" => 31_612_345_678,
            "status" => "sent",
            "statusDatetime" => "2016-05-03T14:26:57+00:00"
          }
        ]
      }
    }
  end
end
