defmodule FastRadius.SupplierNotifications do
  alias FastRadius.{
    Accounts.User,
    Accounts.Permission,
    CostingRequests.SupplierCost,
    Inventory.Location,
    Repo,
    SupplierNotifications
  }

  alias PlatformTools.Subscriptions

  import Ecto.Query

  require Logger

  def send_notification(org_id, notification_type, notification_params) do
    org_id = Map.fetch!(notification_params, "supplier_org_id")

    with {:is_supplier?, true} <- org_is_supplier?(org_id),
         {:ok, entitlements} <- Subscriptions.entitlements(org_id),
         {:is_onboarded?, true} <- supplier_is_onboarded?(entitlements),
         user_ids <- collect_user_ids(org_id) do
      Repo.transaction(fn _repo ->
        Enum.map(user_ids, fn id ->
          id
          |> Map.put(:notification_type, notification_type)
          |> Map.put(:notification_params, notification_params)
          |> SupplierNotifications.Worker.new()
          |> Oban.insert!()
        end)
      end)
    else
      {:is_supplier?, false} -> {:error, :invalid_supplier}
      {:is_onboarded?, false} -> {:error, :invalid_entitlements}
      error -> error
    end
  end


  def collect_user_ids(org_id) do
    User
    |> where([u], u.organization_id == ^org_id and u.verified)
    |> Repo.all()
    |> Enum.filter(&User.has_permission(&1, Permission.names()[:view_supplier_rfqs]))
    |> Enum.map(&%{user_id: &1.id})
  end

  defp get_supplier_cost(id) do
    case Repo.get(SupplierCost, id) do
      nil ->
        {:error, :not_found}

      supplier_cost ->
        {:ok, supplier_cost}
    end
  end

  defp org_is_supplier?(org_id) do
    {:is_supplier?,
     Location
     |> where([l], l.organization_id == ^org_id)
     |> Repo.exists?()}
  end

  defp supplier_is_onboarded?(entitlements),
    do: {:is_onboarded?, Enum.any?(entitlements, &(&1.name == "supplier_portal"))}
end
