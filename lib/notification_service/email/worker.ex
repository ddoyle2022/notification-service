defmodule NotificationService.Email.Worker do
  @ten_minutes 600

  use Oban.Worker,
    queue: :email,
    unique: [
      period: @ten_minutes
    ],
    max_attempts: 5

  alias NotificationService.Mailer

  @impl true
  def perform(%Job{args: %{"email" => email}}) do
    # TODO save copy of email to database, with a status saying whether or not it was delivered

    case Mailer.deliver_now(email, response: true) do
      {:error, _reason} -> :error
      _ -> :ok
    end
  end
end
