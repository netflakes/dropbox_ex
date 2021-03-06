defmodule DropboxEx do
  @moduledoc """
    Documentation for DropboxEx. wrapper for dropbox api v2
  """
  use HTTPoison.Base

  def post(client, url, body \\ "") do
    base_url = default_base_url()
    headers = json_headers()
    post_request(client, "#{base_url}#{url}", body, headers)
  end

  def post_request(client, url, body, headers) do
    headers = Map.merge(headers, headers(client))
    HTTPoison.post!(url, body, headers) |> upload_response
  end

  def download_request(client, url, data, headers) do
    upload_url = default_upload_url()

    headers = Map.merge(headers, headers(client))
    response = HTTPoison.post!("#{upload_url}#{url}", data, headers)
    response
    |> download_response
  end

  def download_response(response) do
    case response do
      {:ok, %{body: body, headers: headers, status_code: 200}} ->
        {:ok, %{file: body, headers: get_header(headers, "dropbox_api_result") |> Poison.decode}}
      _ -> response
    end
  end

  def upload_response(%HTTPoison.Response{status_code: 200, body: body}), do: Poison.decode!(body)
  def upload_response(%HTTPoison.Response{status_code: status_code, body: body }) do
    cond do
    status_code in 400..599 ->
      {{:status_code, status_code}, JSON.decode(body)}
    end
  end

  defp get_header(headers, key) do
    headers
    |> Enum.filter(fn({k, _}) -> k == key end)
    |> hd
    |> elem(1)
  end

  defp headers(client), do: %{ "Authorization" => "Bearer #{client.access_token}" }

  defp json_headers, do: %{ "Content-Type" => "application/json" }

  defp default_base_url, do: "https://api.dropboxapi.com/2/"

  defp default_upload_url, do: "https://content.dropboxapi.com/2/"
end
