class MailboxesController < ApplicationController
  before_action :set_domain
  before_action :set_mailbox, only: %i[ update destroy ]

  def create
    mailbox = @domain.mailboxes.new(params.expect(mailbox: %i[ local_part display_name password quota_mb ]))

    if mailbox.save
      redirect_to domain_path(@domain), notice: "#{mailbox.address} created."
    else
      redirect_to domain_path(@domain), alert: mailbox.errors.full_messages.to_sentence
    end
  end

  # Changes the quota, the active flag, or (only when one is given) the password.
  def update
    attributes = params.expect(mailbox: %i[ display_name password quota_mb active ])
    attributes.delete(:password) if attributes[:password].blank?

    if @mailbox.update(attributes)
      redirect_to domain_path(@domain), notice: "#{@mailbox.address} updated."
    else
      redirect_to domain_path(@domain), alert: @mailbox.errors.full_messages.to_sentence
    end
  end

  # Removes the account. The stored mail stays on disk until it is cleaned up there.
  def destroy
    @mailbox.destroy
    redirect_to domain_path(@domain), notice: "#{@mailbox.address} deleted.", status: :see_other
  end

  private
    def set_domain
      @domain = Domain.find_by!(name: params[:domain_name])
    end

    def set_mailbox
      @mailbox = @domain.mailboxes.find(params[:id])
    end
end
