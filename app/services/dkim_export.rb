# Writes each active domain's DKIM private key, with the KeyTable and
# SigningTable that OpenDKIM reads.
class DkimExport
  def initialize(directory)
    @directory = Pathname(directory)
  end

  def call
    keys = @directory.join("keys")
    keys.mkpath
    domains = Domain.active.ordered.to_a

    domains.each do |domain|
      path = keys.join("#{domain.name}.private")
      path.write(domain.dkim_private_key)
      path.chmod(0o600)
    end

    @directory.join("KeyTable").write(domains.map { |d| "#{d.dkim_record_name} #{d.name}:#{d.dkim_selector}:#{keys.join("#{d.name}.private")}\n" }.join)
    @directory.join("SigningTable").write(domains.map { |d| "*@#{d.name} #{d.dkim_record_name}\n" }.join)
    domains.size
  end
end
