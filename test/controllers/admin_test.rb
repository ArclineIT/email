require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  setup do
    @domain = Domain.create!(name: "example.com")
    @mailbox = @domain.mailboxes.create!(local_part: "blake", password: "correct-horse-1")
    @alias = @domain.mail_aliases.create!(local_part: "info", destinations: "blake@example.com")
  end

  test "lists domains and shows one with its records" do
    get root_path
    assert_select "td a", text: "example.com"

    get domain_path(@domain)
    assert_response :success
    assert_select "td", text: "blake@example.com"
    assert_select "td", text: "info@example.com"
    assert_select "td", text: "arcline._domainkey.example.com"
    assert_no_match "PRIVATE KEY", response.body
    assert_no_match @mailbox.password_digest, response.body
  end

  test "adds a domain and reports a bad one" do
    assert_difference -> { Domain.count } do
      post domains_path, params: { domain: { name: "New-Domain.org" } }
    end
    assert_redirected_to domain_path("new-domain.org")

    post domains_path, params: { domain: { name: "not a domain" } }
    assert_equal "Name is not a valid domain name", flash[:alert]
  end

  test "updates delivery settings" do
    patch domain_path(@domain), params: { domain: { catch_all: "Postmaster@example.com", active: "0" } }
    assert_equal [ "postmaster@example.com", false ], @domain.reload.values_at(:catch_all, :active)

    patch domain_path(@domain), params: { domain: { catch_all: "nope" } }
    assert_match "must be an email address", flash[:alert]
  end

  test "creates, updates and deletes a mailbox" do
    assert_difference -> { Mailbox.count } do
      post domain_mailboxes_path(@domain), params: { mailbox: { local_part: "ops", password: "another-good-1", quota_mb: 500 } }
    end
    ops = Mailbox.find_by!(address: "ops@example.com")

    patch domain_mailbox_path(@domain, ops), params: { mailbox: { quota_mb: 2000, active: "0", password: "" } }
    assert_equal [ 2000, false ], ops.reload.values_at(:quota_mb, :active)
    assert ops.authenticate("another-good-1"), "a blank password field keeps the old password"

    patch domain_mailbox_path(@domain, ops), params: { mailbox: { password: "brand-new-pass-2" } }
    assert ops.reload.authenticate("brand-new-pass-2")

    post domain_mailboxes_path(@domain), params: { mailbox: { local_part: "info", password: "another-good-1", quota_mb: 500 } }
    assert_equal "Local part is already used by an alias", flash[:alert]

    assert_difference -> { Mailbox.count }, -1 do
      delete domain_mailbox_path(@domain, ops)
    end
  end

  test "creates and deletes an alias" do
    assert_difference -> { MailAlias.count } do
      post domain_mail_aliases_path(@domain), params: { mail_alias: { local_part: "sales", destinations: "blake@example.com, x@other.test" } }
    end
    assert_equal "sales@example.com now forwards to blake@example.com and x@other.test.", flash[:notice]

    post domain_mail_aliases_path(@domain), params: { mail_alias: { local_part: "bad", destinations: "nope" } }
    assert_match "has an invalid address", flash[:alert]

    assert_difference -> { MailAlias.count }, -1 do
      delete domain_mail_alias_path(@domain, @alias)
    end
  end

  test "a mailbox cannot be changed through another domain" do
    other = Domain.create!(name: "other.org")

    delete domain_mailbox_path(other, @mailbox)
    assert_response :not_found
    assert Mailbox.exists?(@mailbox.id)
  end

  test "checks published DNS and shows the result" do
    stub_method(DnsLookup, :new, FakeDns.new(mx: { "example.com" => [ "mail.arclineit.com" ] })) do
      post check_dns_domain_path(@domain)
    end
    follow_redirect!

    assert_select ".findings__item", 4
    assert_select ".status-badge--ok", text: "MX"
    assert_select ".findings__item", text: /no DMARC record/
  end

  test "generates a new DKIM key" do
    before = @domain.dkim_public_key
    post rotate_dkim_domain_path(@domain)

    assert_not_equal before, @domain.reload.dkim_public_key
  end

  test "deletes a domain with everything in it" do
    assert_difference -> { Domain.count } => -1, -> { Mailbox.count } => -1, -> { MailAlias.count } => -1 do
      delete domain_path(@domain)
    end
  end

  test "answers in JSON without keys or password hashes" do
    get domains_path, headers: { "Accept" => "application/json" }
    assert_equal [ { "name" => "example.com", "active" => true, "catch_all" => nil, "mailboxes" => 1, "aliases" => 1 } ], response.parsed_body

    get domain_path(@domain), headers: { "Accept" => "application/json" }
    body = response.parsed_body
    assert_equal [ "blake@example.com" ], body["mailboxes"].map { |m| m["address"] }
    assert_equal [ [ "blake@example.com" ] ], body["aliases"].map { |a| a["destinations"] }
    assert_equal 4, body["dns_records"].size
    assert_no_match(/PRIVATE KEY|\$2a\$/, response.body)
  end

  test "everything needs the admin login when one is configured" do
    settings = Rails.configuration.x.email
    settings.username, settings.password = "admin", "s3cret-pass"

    get root_path
    assert_response :unauthorized
    assert_no_difference [ -> { Domain.count }, -> { Mailbox.count } ] do
      post domains_path, params: { domain: { name: "x.org" } }
      delete domain_path(@domain)
      delete domain_mailbox_path(@domain, @mailbox)
    end
    assert_response :unauthorized

    get root_path, headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "s3cret-pass") }
    assert_response :success
    get rails_health_check_path
    assert_response :success
  ensure
    settings.username = settings.password = nil
  end
end
