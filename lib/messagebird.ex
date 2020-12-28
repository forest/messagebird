defmodule Messagebird do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use Supervisor

  @messagebird_api_schema [
    base_url: [
      type: :string,
      required: true
    ],
    access_key: [
      type: :string,
      required: true
    ],
    backend: [
      type: :any
    ]
  ]

  @messagebird_sms_schema [
    originator: [
      type: :string,
      required: true,
      doc:
        "The sender of the message. This can be a telephone number (including country code) or an alphanumeric string."
    ],
    scheduledDatetime: [
      type: :string,
      required: false,
      doc: "The scheduled date and time of the message in RFC3339 format (Y-m-dTH:i:sP)"
    ],
    validity: [
      type: :pos_integer,
      required: false,
      doc:
        "The amount of seconds that the message is valid. If a message is not delivered within this time, the message will be discarded."
    ],
    datacoding: [
      type: {:in, ["plain", "unicode", "auto"]},
      default: "plain",
      doc:
        "The datacoding used can be `plain` (GSM 03.38 characters only), `unicode` (contains non-GSM 03.38 characters) or `auto`, we will then set unicode or plain depending on the body content."
    ]
  ]

  def child_spec(opts) do
    %{
      id: opts[:name] || raise(ArgumentError, "must supply a name"),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc """
  Start an instance of Messagebird.

  ## Options

    * `:name` - The name of your Messagebird instance. This field is required.
  """
  def start_link(opts) do
    name = opts[:name] || raise ArgumentError, "must supply a name"

    config = %{
      http_client_name: http_client_name(name),
      sms_service_name: sms_service_name(name)
    }

    Supervisor.start_link(__MODULE__, config, name: supervisor_name(name))
  end

  @impl true
  def init(config) do
    children = [
      {Finch, [name: config.http_client_name]},
      {Messagebird.SMS, [name: config.sms_service_name, config: config]},
      {Messagebird.Backend.InMemory.Server, [name: Messagebird.Backend.InMemory.Server]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Sends an SMS to the recipient

  ## API Configuration

  #{NimbleOptions.docs(@messagebird_api_schema)}

  ## SMS Options

  #{NimbleOptions.docs(@messagebird_sms_schema)}
  """
  def send_text_message(name, config, recipient, message, options) do
    Messagebird.SMS.send_text_message(
      sms_service_name(name),
      validate_api_config!(config),
      recipient,
      message,
      validate_sms_options!(options)
    )
  end

  defp validate_api_config!(config) do
    case NimbleOptions.validate(config, @messagebird_api_schema) do
      {:ok, valid} ->
        valid_api_config_to_map(valid)

      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise ArgumentError,
              "got invalid configuration for API: #{Exception.message(error)}"
    end
  end

  defp validate_sms_options!(opts) do
    case NimbleOptions.validate(opts, @messagebird_sms_schema) do
      {:ok, valid} ->
        valid_sms_opts_to_map(valid)

      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise ArgumentError,
              "got invalid configuration for SMS Service: #{Exception.message(error)}"
    end
  end

  defp valid_api_config_to_map(valid) do
    %{
      base_url: valid[:base_url],
      access_key: valid[:access_key],
      backend: valid[:backend]
    }
    |> drop_nils()
  end

  defp valid_sms_opts_to_map(valid) do
    %{
      originator: valid[:originator],
      scheduledDatetime: valid[:scheduledDatetime],
      validity: valid[:validity],
      datacoding: valid[:datacoding]
    }
    |> drop_nils()
  end

  defp supervisor_name(name), do: :"#{name}.Supervisor"
  defp http_client_name(name), do: :"#{name}.HTTPClient"
  defp sms_service_name(name), do: :"#{name}.Services.SMS"

  def drop_nils(params) when is_map(params) do
    Enum.reject(params, fn {_key, value} ->
      is_nil(value)
    end)
    |> Enum.into(%{})
  end

  defmacro __using__(_opts) do
    quote do
      def child_spec(opts) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Messagebird.child_spec(opts)
      end

      def start_link(opts) do
        opts = Keyword.put_new(opts, :name, __MODULE__)
        Messagebird.start_link(opts)
      end

      def send_text_message(config, recipient, message, options),
        do: Messagebird.send_text_message(__MODULE__, config, recipient, message, options)
    end
  end
end
