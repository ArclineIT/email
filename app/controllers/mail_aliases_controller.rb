class MailAliasesController < ApplicationController
  before_action :set_domain

  def create
    mail_alias = @domain.mail_aliases.new(params.expect(mail_alias: %i[ local_part destinations ]))

    if mail_alias.save
      redirect_to domain_path(@domain), notice: "#{mail_alias.address} now forwards to #{mail_alias.destination_list.to_sentence}."
    else
      redirect_to domain_path(@domain), alert: mail_alias.errors.full_messages.to_sentence
    end
  end

  def update
    mail_alias = @domain.mail_aliases.find(params[:id])

    if mail_alias.update(params.expect(mail_alias: %i[ destinations active ]))
      redirect_to domain_path(@domain), notice: "#{mail_alias.address} updated."
    else
      redirect_to domain_path(@domain), alert: mail_alias.errors.full_messages.to_sentence
    end
  end

  def destroy
    mail_alias = @domain.mail_aliases.find(params[:id]).destroy
    redirect_to domain_path(@domain), notice: "#{mail_alias.address} deleted.", status: :see_other
  end

  private
    def set_domain
      @domain = Domain.find_by!(name: params[:domain_name])
    end
end
