defmodule IntegrationTest do
  use ExUnit.Case, async: false

  setup do
    config = base_url() |> api_config()

    {:ok, api_config: config}
  end

  describe "send sms message" do
    test "successful request, with valid message details", %{api_config: config} do
      start_supervised!({TestMessagebirdClient, []})

      assert {:ok,
              %{
                "body" => "Test message",
                "datacoding" => "plain",
                "direction" => "mt",
                "mclass" => 1,
                "originator" => "TEST",
                "recipients" => %{
                  "items" => [
                    %{
                      "messagePartCount" => 1,
                      "recipient" => 18_054_530_814,
                      "status" => "sent"
                    }
                  ],
                  "totalCount" => 1,
                  "totalDeliveredCount" => 0,
                  "totalDeliveryFailedCount" => 0,
                  "totalSentCount" => 1
                },
                "type" => "sms"
              }} =
               TestMessagebirdClient.send_text_message(config, "+18054530814", "Test message",
                 originator: "TEST"
               )
    end

    test "fails request, with bad basic auth header", %{api_config: config} do
      config = put_in(config, [:access_key], "badbad")
      start_supervised!({TestMessagebirdClient, []})

      assert {:error,
              %{
                "errors" => [
                  %{
                    "code" => 2,
                    "description" => "Request not allowed (incorrect access_key)",
                    "parameter" => "access_key"
                  }
                ]
              }} =
               TestMessagebirdClient.send_text_message(config, "+18054530814", "Test message",
                 originator: "TEST"
               )
    end

    test "fails request, with bad data", %{api_config: config} do
      start_supervised!({TestMessagebirdClient, []})

      assert {:error,
              %{
                "errors" => [
                  %{
                    "code" => 9,
                    "parameter" => "recipient"
                  }
                ]
              }} =
               TestMessagebirdClient.send_text_message(config, "junk", "Test message",
                 originator: "TEST"
               )
    end
  end

  defp api_config(base_url),
    do: [base_url: base_url, access_key: System.fetch_env!("ACCESS_KEY")]

  defp base_url, do: "https://rest.messagebird.com"
end
