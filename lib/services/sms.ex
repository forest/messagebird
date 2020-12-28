defmodule Messagebird.SMS do
  @moduledoc false
  use GenServer

  @backend Messagebird.Backend.API

  def child_spec(opts) do
    %{
      id: opts[:name],
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    config = %{http_client_name: get_in(opts, [:config, :http_client_name])}

    {:ok, config}
  end

  def send_text_message(server, config, recipient, message, options) do
    GenServer.call(server, {:send_text_message, config, recipient, message, options})
  end

  def handle_call({:send_text_message, config, recipient, message, options}, _from, state) do
    defaults = %{
      recipients: recipient,
      body: message
      # originator: Messagebird.originator()
    }

    options = Map.merge(defaults, options)
    {backend, config} = Map.pop(config, :backend, @backend)

    response = backend.send_message(api_config(config, state), options)

    {:reply, response, state}
  end

  defp api_config(config, state) do
    state |> Map.merge(config)
  end
end
