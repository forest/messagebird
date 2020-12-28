defmodule Messagebird.Backend.Behaviour do
  @moduledoc """
  Implement this behaviour for custom backends.
  """

  @type send_message_config :: %{
          http_client_name: String.t(),
          base_url: String.t(),
          access_key: String.t()
        }

  @type send_message_body :: %{
          originator: String.t(),
          scheduledDateTime: String.t(),
          validity: integer,
          datacoding: :plain | :auto | :unicode,
          body: String.t(),
          recipients: String.t()
        }

  @callback send_message(__MODULE__.send_message_config(), __MODULE__.send_message_body()) ::
              {:ok, term()} | {:error, map()}
end
