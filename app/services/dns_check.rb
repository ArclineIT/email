# Compares what a domain should publish in DNS with what it actually does.
class DnsCheck
  Result = Data.define(:label, :status, :detail) do
    def ok? = status == "ok"
  end

  def initialize(domain, dns: DnsLookup.new, mail_host: Rails.configuration.x.email.mail_host)
    @domain = domain
    @dns = dns
    @mail_host = mail_host
  end

  def call
    [ mx, spf, dkim, dmarc ]
  end

  private
    def result(label, ok, detail)
      Result.new(label: label, status: ok ? "ok" : "missing", detail: detail)
    end

    def mx
      hosts = @dns.mx(@domain.name).map { |host| host.downcase.chomp(".") }

      if hosts.include?(@mail_host.downcase) then result("MX", true, "points at #{@mail_host}")
      elsif hosts.any? then result("MX", false, "points at #{hosts.join(', ')}, not #{@mail_host}")
      else result("MX", false, "no MX record")
      end
    end

    def spf
      record = @dns.txt(@domain.name).find { |txt| txt.downcase.start_with?("v=spf1") }
      return result("SPF", false, "no SPF record") if record.nil?

      result("SPF", record.match?(/\bmx\b|#{Regexp.escape(@mail_host)}/i), record.truncate(120))
    end

    def dkim
      record = @dns.txt(@domain.dkim_record_name).join
      return result("DKIM", false, "no record at #{@domain.dkim_record_name}") if record.blank?

      published = record[/p=([A-Za-z0-9+\/=\s]+)/, 1].to_s.gsub(/\s/, "")
      published == @domain.dkim_public_key ? result("DKIM", true, "key matches") : result("DKIM", false, "a different key is published")
    end

    def dmarc
      record = @dns.txt("_dmarc.#{@domain.name}").find { |txt| txt.downcase.start_with?("v=dmarc1") }
      record ? result("DMARC", true, record.truncate(120)) : result("DMARC", false, "no DMARC record")
    end
end
