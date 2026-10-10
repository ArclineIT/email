class DomainsController < ApplicationController
  before_action :set_domain, only: %i[ show update destroy check_dns rotate_dkim ]

  def index
    @domains = Domain.ordered.includes(:mailboxes, :mail_aliases)
    @domain = Domain.new

    respond_to do |format|
      format.html
      format.json { render json: @domains.map { |domain| domain_json(domain) } }
    end
  end

  def show
    @mailboxes = @domain.mailboxes.ordered
    @aliases = @domain.mail_aliases.ordered
    @mailbox = @domain.mailboxes.new
    @alias = @domain.mail_aliases.new
    @checks = flash[:checks]&.map { |check| DnsCheck::Result.new(**check.symbolize_keys) }

    respond_to do |format|
      format.html
      format.json { render json: domain_json(@domain).merge(dns_records: @domain.dns_records, mailboxes: @mailboxes.map { |m| mailbox_json(m) }, aliases: @aliases.map { |a| alias_json(a) }) }
    end
  end

  def create
    @domain = Domain.new(params.expect(domain: %i[ name ]))

    if @domain.save
      redirect_to domain_path(@domain), notice: "#{@domain.name} added. Publish the DNS records below."
    else
      redirect_to domains_path, alert: @domain.errors.full_messages.to_sentence
    end
  end

  def update
    if @domain.update(params.expect(domain: %i[ active catch_all ]))
      redirect_to domain_path(@domain), notice: "#{@domain.name} updated."
    else
      redirect_to domain_path(@domain), alert: @domain.errors.full_messages.to_sentence
    end
  end

  def destroy
    @domain.destroy
    redirect_to domains_path, notice: "#{@domain.name} and its mailboxes were deleted.", status: :see_other
  end

  def check_dns
    flash[:checks] = DnsCheck.new(@domain).call.map(&:to_h)
    redirect_to domain_path(@domain, anchor: "dns")
  end

  # Signing breaks until the new record is published and the key is exported again.
  def rotate_dkim
    @domain.generate_dkim_key
    @domain.save!
    redirect_to domain_path(@domain, anchor: "dns"), notice: "New DKIM key generated. Publish the new record and export the keys again."
  end

  private
    def set_domain
      @domain = Domain.find_by!(name: params[:name])
    end

    def domain_json(domain)
      { name: domain.name, active: domain.active, catch_all: domain.catch_all.presence, mailboxes: domain.mailboxes.size, aliases: domain.mail_aliases.size }
    end

    def mailbox_json(mailbox)
      { address: mailbox.address, display_name: mailbox.display_name, quota_mb: mailbox.quota_mb, active: mailbox.active }
    end

    def alias_json(mail_alias)
      { address: mail_alias.address, destinations: mail_alias.destination_list, active: mail_alias.active }
    end
end
