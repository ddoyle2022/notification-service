defmodule NotificationController do
  @moduledoc ""

  use UsersApiWeb, :controller
  use Phoenix.Controller

  alias UsersApi.Admin
  alias UsersApi.Admin.Email

  action_fallback NotificationServiceWeb.ErrorController

  def send_email(conn, %{"notification_category" => category} = params) do
    type = Map.get(params, "notification_type", "consulting")
    params = Map.get(params, "notification_params", %{})

    case EmailNotifications.send_email(category, type, params) do
      {:ok, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: %{success: true}}))

      {:error, message} ->
        conn
        |> send_resp(422, Jason.encode!(%{data: message}))
    end
  end
end
