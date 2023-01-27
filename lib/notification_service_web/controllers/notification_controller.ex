defmodule NotificationController do
  @moduledoc "Web/App level logic. Get and sanitize parameters, delegate procressing, send correct HTTP responses"

  use UsersApiWeb, :controller
  use Phoenix.Controller

  alias UsersApi.Admin
  alias UsersApi.Admin.Email

  action_fallback NotificationServiceWeb.ErrorController

  @doc ""
  def send_email(conn, %{"user" => user, "notification_category" => notification_category} = params) do
    category = notification_category |> String.to_existing_atom()
    type = Map.get(params, "notification_type") |> String.to_existing_atom()
    params = Map.get(params, "notification_params")

    recipients = %{
      user: user,
      cc: Map.get(params, "cc", []) |> sanitize_addresses(),
      bcc: Map.get(params, "bcc", []) |> sanitize_addresses()
    }

    case EmailNotifications.send_email(recipients, category, type, params) do
      {:ok, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: %{success: true}}))

      {:error, message} ->
        conn
        |> send_resp(422, Jason.encode!(%{data: message}))
    end
  end

  @doc ""
  def send_slack_message() do

  end

  defp sanitize_addresses(addresses) do
    addresses
    |> List.wrap()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end
end
