defmodule Messagebird.Backend.API do
  @moduledoc """
  The default backend that calls the Messagebird API
  """

  @behaviour Messagebird.Backend.Behaviour

  @success_response_codes [200, 201, 202, 204]
  @failure_response_code [401, 404, 405, 422]

  @impl true
  def send_message(config, body) do
    request = build_request(config, :post, "/messages", body)

    case make_request(config, request) do
      {:ok, %Finch.Response{status: status, body: body}} when status in @success_response_codes ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status, body: body}} when status in @failure_response_code ->
        {:error, Jason.decode!(body)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp build_request(config, method, path, body) when is_atom(method) do
    base_url = base_url_from_config(config)
    headers = headers_from_config(config)

    Finch.build(method, base_url <> path, headers, Jason.encode!(body))
  end

  defp make_request(config, request, opts \\ []) do
    name = http_client_name_from_config(config)

    Finch.request(request, name, opts)
  end

  defp base_url_from_config(%{base_url: base_url}), do: base_url

  defp http_client_name_from_config(%{http_client_name: name}), do: name

  defp headers_from_config(config) do
    [basic_auth_header(config), content_type_header(), accept_header()]
  end

  defp basic_auth_header(%{access_key: access_key}) do
    {"Authorization", "AccessKey " <> access_key}
  end

  defp content_type_header, do: {"Content-Type", "application/json"}
  defp accept_header, do: {"Accept", "application/json"}
end
