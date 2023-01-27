defmodule NotificationService.Email.SupplierEmails do
  use Bamboo.Phoenix, view: FastRadiusWeb.EmailView

  def build_email(%{user: user, cc: cc, bcc: bcc}, rfq_type, _attrs) when rfq_type in [:consulting, :ready_to_order] do
    subject =
      case rfq_type do
        :consulting -> "We sent you a new RFQ"
        :ready_to_order -> "We sent you a new RFQ that's ready to order"
      end

    base_email()
    |> Bamboo.SendGridHelper.with_categories([
      sendgrid_categories(:welcome),
      sendgrid_categories(:customer)
    ])
    |> to_user(user)
    |> cc(cc)
    |> bcc(bcc)
    |> subject(subject)
    |> assign(:partner_portal_link, supplier_portal_link(:rfq))
    |> assign(:rfq_type, rfq_type)
    |> render(:new_rfq_in_partner_portal)
  end

  def build_email(%{user: user, cc: cc, bcc: bcc}, :quote_request_deleted, %{"quote_request_id" => quote_request_id}) do
    base_email()
    |> to_user(user)
    |> cc(cc)
    |> bcc(bcc)
    |> subject("We've removed RFQ ##{quote_request_id}")
    |> assign(:partner_portal_link, supplier_portal_link(:rfq))
    |> assign(:quote_request_id, quote_request_id)
    |> render(:deleted_rfq_in_partner_portal)
  end

  def build_email(%{user: user, cc: cc, bcc: bcc}, :new_purchase_order, %{"purchase_order_number" => po_number} = attrs) do
    internal =
      [
        supply_chain_team(),
        attrs["support_contact_email"]
      ]
      |> sanitize_addresses()

    base_email()
    |> to_user(user)
    |> cc(cc)
    |> bcc(bcc)
    |> cc(internal)
    |> subject("We sent you a new Job #{po_number}")
    |> assign(:partner_portal_link, supplier_portal_link(:job))
    |> assign(:purchase_order_number, po_number)
    |> render(:new_supplier_purchase_order)
  end

  def build_email(%{user: user, cc: cc, bcc: bcc}, :purchase_order_update, %{"purchase_order_number" => po_number} = attrs) do
    internal =
      [
        supply_chain_team(),
        attrs["support_contact_email"]
      ]
      |> sanitize_addresses()

    base_email()
    |> to_user(user)
    |> cc(internal)
    |> subject("We've updated Job #{po_number}")
    |> assign(:partner_portal_link, supplier_portal_link(:job))
    |> assign(:purchase_order_number, po_number)
    |> render(:updated_supplier_purchase_order)
  end

  def build_email(%{user: user, cc: cc, bcc: bcc}, :purchase_order_invalidated, %{"purchase_order_number" => po_number}) do
    base_email()
    |> to_user(user)
    |> cc(cc)
    |> bcc(bcc)
    |> subject("We've removed Job #{po_number}")
    |> assign(:partner_portal_link, supplier_portal_link(:job))
    |> assign(:purchase_order_number, po_number)
    |> render(:invalidated_supplier_purchase_order)
  end

  # the user here is the supplier portal user, but we're sending the email to our internal team
  def build_email(
        %{organization: %{name: partner_name}} = _user,
        :confirmed_purchase_order,
        %{"purchase_order_number" => po_number} = attrs
      ) do
    cc_addresses =
      [
        attrs["support_contact_email"]
      ]
      |> sanitize_addresses()

    base_email()
    |> to(supply_chain_team())
    |> cc(cc_addresses)
    |> subject("Job #{po_number} confirmed by #{partner_name}")
    |> assign(:partner_portal_link, supplier_portal_link(:job))
    |> assign(:name, "Supply Chain Team")
    |> assign(:to_email, supply_chain_team())
    |> assign(:partner_name, partner_name)
    |> assign(:purchase_order_number, po_number)
    |> render(:confirmed_supplier_purchase_order)
  end

  defp base_email() do
    new_email()
    |> from(no_reply_email())
    |> assign(:footer, true)
    |> put_html_layout({FastRadiusWeb.LayoutView, "email_v2.html"})
    |> put_text_layout({FastRadiusWeb.LayoutView, "email.text"})
  end

  defp to_user(email, user) do
    email
    |> to(user.email)
    |> assign(:name, User.name(user))
    |> assign(:to_email, user.email)
  end

  def no_reply_email do
    FastRadius.Email.no_reply_email()
  end

  def supplier_portal_link(:rfq) do
    "#{supplier_portal_link()}/rfqs"
  end

  def supplier_portal_link(:job) do
    "#{supplier_portal_link()}/jobs"
  end

  defp supplier_portal_link() do
    "https://#{subdomain()}.fastradius.com/supplier-portal"
  end

  def subdomain do
    if logical_env() == :prod,
      do: "os",
      else: "beta"
  end

  def supply_chain_team do
    if logical_env() == :prod,
      do: "scops@fastradius.com",
      else: "dev+beta+scops@fastradius.com"
  end

  defp sendgrid_categories(key) do
    FastRadius.Email.sendgrid_categories(key)
  end

  defp logical_env do
    Application.fetch_env!(:fast_radius, :logical_environment)
  end
end
