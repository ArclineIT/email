namespace :email do
  desc "Write DKIM keys, KeyTable and SigningTable for OpenDKIM: bin/rails 'email:dkim_export[/etc/opendkim]'"
  task :dkim_export, [ :directory ] => :environment do |_task, args|
    directory = args[:directory] or abort "usage: bin/rails 'email:dkim_export[/etc/opendkim]'"
    puts "Wrote keys for #{DkimExport.new(directory).call} domains to #{directory}."
  end

  desc "Print the DNS records a domain needs: bin/rails 'email:dns[example.com]'"
  task :dns, [ :domain ] => :environment do |_task, args|
    domain = Domain.find_by(name: args[:domain].to_s.downcase) or abort "no domain #{args[:domain].inspect}"
    domain.dns_records.each { |record| puts format("%-4s %-40s %s", record[:type], record[:name], record[:value]) }
  end
end
