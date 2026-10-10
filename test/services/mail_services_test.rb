require "test_helper"

class MailServicesTest < ActiveSupport::TestCase
  setup { @domain = Domain.create!(name: "example.com") }

  test "a correctly published domain passes every DNS check" do
    dns = FakeDns.new(mx: { "example.com" => [ "Mail.ArclineIT.com" ] },
                      txt: { "example.com" => [ "v=spf1 mx -all" ], @domain.dkim_record_name => [ @domain.dkim_record_value ],
                             "_dmarc.example.com" => [ "v=DMARC1; p=quarantine" ] })
    results = DnsCheck.new(@domain, dns: dns, mail_host: "mail.arclineit.com").call

    assert_equal %w[ MX SPF DKIM DMARC ], results.map(&:label)
    assert results.all?(&:ok?), results.reject(&:ok?).map(&:detail).inspect
  end

  test "missing and wrong records are explained" do
    other_key = Domain.new(name: "x.test").tap(&:generate_dkim_key).dkim_record_value
    dns = FakeDns.new(mx: { "example.com" => [ "mx.other-host.net" ] }, txt: { "example.com" => [ "v=spf1 include:_spf.google.com ~all" ], @domain.dkim_record_name => [ other_key ] })
    results = DnsCheck.new(@domain, dns: dns, mail_host: "mail.arclineit.com").call.index_by(&:label)

    assert_equal "points at mx.other-host.net, not mail.arclineit.com", results["MX"].detail
    assert_not results["SPF"].ok?
    assert_equal "a different key is published", results["DKIM"].detail
    assert_equal "no DMARC record", results["DMARC"].detail

    empty = DnsCheck.new(@domain, dns: FakeDns.new, mail_host: "mail.arclineit.com").call
    assert_equal [ "no MX record", "no SPF record", "no record at arcline._domainkey.example.com", "no DMARC record" ], empty.map(&:detail)
  end

  test "exports DKIM keys and tables for active domains only" do
    Domain.create!(name: "disabled.org", active: false)
    directory = Rails.root.join("tmp", "dkim-test-#{SecureRandom.hex(4)}")

    assert_equal 1, DkimExport.new(directory).call
    key = directory.join("keys/example.com.private")
    assert_equal @domain.dkim_private_key, key.read
    assert_equal "600", format("%o", key.stat.mode & 0o777)
    assert_equal "arcline._domainkey.example.com example.com:arcline:#{key}\n", directory.join("KeyTable").read
    assert_equal "*@example.com arcline._domainkey.example.com\n", directory.join("SigningTable").read
    assert_not directory.join("keys/disabled.org.private").exist?
  ensure
    FileUtils.rm_rf(directory)
  end

  test "the queries shipped for Postfix and Dovecot run against the real schema" do
    @domain.update!(catch_all: "postmaster@example.com")
    @domain.mailboxes.create!(local_part: "blake", password: "correct-horse-1", quota_mb: 2048)
    @domain.mail_aliases.create!(local_part: "info", destinations: "blake@example.com,other@elsewhere.test")
    off = Domain.create!(name: "off.org", active: false)
    off.mailboxes.create!(local_part: "ghost", password: "correct-horse-1")

    assert_equal [ [ 1 ] ], run_query("postfix/sqlite-virtual-domains.cf", "example.com")
    assert_empty run_query("postfix/sqlite-virtual-domains.cf", "off.org")
    assert_equal [ [ "example.com/blake/" ] ], run_query("postfix/sqlite-virtual-mailboxes.cf", "blake@example.com")
    assert_empty run_query("postfix/sqlite-virtual-mailboxes.cf", "ghost@off.org")
    assert_equal [ [ "blake@example.com,other@elsewhere.test" ] ], run_query("postfix/sqlite-virtual-aliases.cf", "info@example.com")
    assert_equal [ [ "postmaster@example.com" ] ], run_query("postfix/sqlite-virtual-catchall.cf", "@example.com")
    assert_equal [ [ "blake@example.com" ] ], run_query("postfix/sqlite-virtual-mailbox-identity.cf", "blake@example.com")

    password = run_dovecot("password_query", "blake@example.com").sole
    assert BCrypt::Password.new(password["password"]).is_password?("correct-horse-1")
    user = run_dovecot("user_query", "blake@example.com").sole
    assert_equal [ "/var/mail/example.com/blake", "*:storage=2048M" ], user.values_at("home", "quota_rule")
    assert_empty run_dovecot("password_query", "ghost@off.org")
  end

  private
    def run_query(file, value)
      sql = Rails.root.join("deploy", file).read[/^query = (.*)\z/m, 1].gsub("'%s'", ActiveRecord::Base.connection.quote(value))
      ActiveRecord::Base.connection.select_rows(sql)
    end

    def run_dovecot(name, user)
      text = Rails.root.join("deploy/dovecot/dovecot-sql.conf.ext").read.gsub("\\\n", " ")
      sql = text[/^#{name} = (.*)$/, 1].gsub("'%u'", ActiveRecord::Base.connection.quote(user))
      ActiveRecord::Base.connection.select_all(sql).to_a
    end
end
