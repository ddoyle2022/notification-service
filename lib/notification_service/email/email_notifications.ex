defmodule  NotificationService.Email.EmailNotifications do
  @moduledoc "Responsible for building the correct email and creating an Oban job to send + record the email."

  def send_email(recipients, category, type, params) do
    email =
      case category do
        :supplier -> SupplierEmails.build(recipients, type, params)
        :customer -> CustomerEmails.build(recipients, type, params)
        :internal -> InternalEmails.build(recipients, type, params)
      end

    email
    |> NotificationService.Email.Worker.new()
    |> Oban.insert!()
  end
end
