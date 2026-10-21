require "test_helper"

class MailModelsTest < ActiveSupport::TestCase
  setup { @domain = Domain.create!(name: " Example.COM. ") }

  test "a domain is normalized, validated and gets a DKIM key" do
    assert_equal "example.com", @domain.name
    assert_match "BEGIN RSA PRIVATE KEY", @domain.dkim_private_key
    assert_equal 2048, OpenSSL::PKey::RSA.new(@domain.dkim_private_key).n.num_bits

    [ "", "localhost", "exa mple.com", "example", "-bad.com", "example.com" ].each { |name| assert_not Domain.new(name: name).valid?, name.inspect }
    assert_not Domain.new(name: "other.com", catch_all: "not an address").valid?
  end

  test "lists the DNS records to publish" do
    records = @domain.dns_records(mail_host: "mail.arcline.it")

    assert_equal [ [ "MX", "example.com", "10 mail.arcline.it." ], [ "TXT", "example.com", "v=spf1 mx -all" ] ], records.first(2).map(&:values)
    assert_equal "arcline._domainkey.example.com", records[2][:name]
    assert_match(/\Av=DKIM1; k=rsa; p=[A-Za-z0-9+\/=]{300,}\z/, records[2][:value])
    assert_equal [ "_dmarc.example.com", "v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com" ], records[3].values_at(:name, :value)
  end

  test "a mailbox has a full address, a bcrypt password and a maildir" do
    mailbox = @domain.mailboxes.create!(local_part: " Blake@whatever.test ", password: "correct-horse-1", display_name: "Blake")

    assert_equal [ "blake", "blake@example.com", "example.com/blake/" ], [ mailbox.local_part, mailbox.address, mailbox.maildir ]
    assert mailbox.password_digest.start_with?("$2a$")
    assert mailbox.authenticate("correct-horse-1")
    assert_equal 1024, mailbox.quota_mb
  end

  test "mailbox passwords, local parts and quotas are validated" do
    assert_not @domain.mailboxes.new(local_part: "a", password: "short").valid?
    assert_not @domain.mailboxes.new(local_part: "a", password: "correct-horse-1", quota_mb: 0).valid?
    [ "", "has space", ".lead", "trail.", "a/b", "ü" ].each do |part|
      assert_not @domain.mailboxes.new(local_part: part, password: "correct-horse-1").valid?, part.inspect
    end
    assert @domain.mailboxes.new(local_part: "first.last+tag", password: "correct-horse-1").valid?
  end

  test "an alias forwards to a cleaned list of addresses" do
    mail_alias = @domain.mail_aliases.create!(local_part: "info", destinations: "Blake@example.com;  other@elsewhere.test\nblake@example.com")

    assert_equal "info@example.com", mail_alias.address
    assert_equal %w[ blake@example.com other@elsewhere.test ], mail_alias.destination_list
  end

  test "an alias needs valid destinations and cannot loop to itself" do
    assert_not @domain.mail_aliases.new(local_part: "info", destinations: "").valid?
    assert_not @domain.mail_aliases.new(local_part: "info", destinations: "not-an-address").valid?
    assert_not @domain.mail_aliases.new(local_part: "info", destinations: "info@example.com").valid?
  end

  test "an address belongs to one mailbox or one alias" do
    @domain.mailboxes.create!(local_part: "blake", password: "correct-horse-1")
    @domain.mail_aliases.create!(local_part: "info", destinations: "blake@example.com")

    assert_equal [ "Local part is already used by a mailbox" ], @domain.mail_aliases.new(local_part: "blake", destinations: "x@y.test").tap(&:valid?).errors.full_messages
    assert_equal [ "Local part is already used by an alias" ], @domain.mailboxes.new(local_part: "info", password: "correct-horse-1").tap(&:valid?).errors.full_messages
    assert_not @domain.mailboxes.new(local_part: "blake", password: "correct-horse-1").valid?

    other = Domain.create!(name: "other.org")
    assert other.mailboxes.new(local_part: "blake", password: "correct-horse-1").valid?
  end

  test "deleting a domain deletes its mailboxes and aliases" do
    @domain.mailboxes.create!(local_part: "blake", password: "correct-horse-1")
    @domain.mail_aliases.create!(local_part: "info", destinations: "blake@example.com")

    assert_difference -> { Mailbox.count } => -1, -> { MailAlias.count } => -1 do
      @domain.destroy
    end
  end
end
