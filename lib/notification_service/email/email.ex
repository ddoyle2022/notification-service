defmodule NotificationService.Email.Email do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "email" do
    field :to, :string
    field :cc, :string
    field :bcc, :string
    field :subject, :string
    field :body, :string
    field :was_sent, :boolean
    # attachments?

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:to, :cc, :bcc, :subject, :body])
    |> validate_required([:to, :subject, :body])
  end
end
