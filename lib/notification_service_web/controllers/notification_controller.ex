defmodule NotificationController do
  use Phoenix.Controller

  def call(conn, _) do
    conn
    |> put_status(:not_found)
    |> put_view(MyErrorView)
    |> render(:"404")
  end
end
