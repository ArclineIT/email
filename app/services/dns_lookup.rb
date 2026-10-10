require "resolv"

# The DNS questions this app asks, each with a timeout and without raising.
class DnsLookup
  TIMEOUT = 5
  DS = Resolv::DNS::Resource::Generic.create(43, Resolv::DNS::Resource::IN::ClassValue)

  def addresses(host)
    query { |dns| dns.getaddresses(host).map(&:to_s) } || []
  end

  def reverse(ip)
    query { |dns| dns.getname(ip).to_s }
  end

  def txt(name)
    query { |dns| dns.getresources(name, Resolv::DNS::Resource::IN::TXT).map { |record| record.strings.join } } || []
  end

  # Mail servers, lowest preference first.
  def mx(name)
    records = query { |dns| dns.getresources(name, Resolv::DNS::Resource::IN::MX) } || []
    records.sort_by(&:preference).map { |record| record.exchange.to_s }
  end

  # Whether the parent zone holds a DS record for the name, which is what
  # switches DNSSEC on.
  def dnssec?(name)
    (query { |dns| dns.getresources(name, DS) } || []).any?
  end

  private
    def query
      Resolv::DNS.open do |dns|
        dns.timeouts = TIMEOUT
        yield dns
      end
    rescue Resolv::ResolvError, Resolv::ResolvTimeout, SystemCallError
      nil
    end
end
