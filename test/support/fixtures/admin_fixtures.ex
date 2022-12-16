defmodule NotificationService.AdminFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `NotificationService.Admin` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{

      })
      |> NotificationService.Admin.create_user()

    user
  end
end
