# Shared by mailboxes and aliases: a local part within a domain, and the full
# address kept alongside it. An address belongs to one mailbox or one alias.
module HasAddress
  extend ActiveSupport::Concern

  LOCAL_PART = /\A[a-z0-9]([a-z0-9._+-]{0,62}[a-z0-9])?\z/

  included do
    belongs_to :domain

    normalizes :local_part, with: ->(part) { part.to_s.strip.downcase.sub(/@.*\z/, "") }

    before_validation { self.address = "#{local_part}@#{domain.name}" if domain }

    validates :local_part, presence: true, format: { with: LOCAL_PART, message: "may only use letters, digits, dots, hyphens, underscores and plus signs" }
    validates :address, uniqueness: true
    validate :address_not_taken_elsewhere

    scope :ordered, -> { order(:address) }
    scope :active, -> { where(active: true) }
  end

  private
    def address_not_taken_elsewhere
      other = is_a?(Mailbox) ? MailAlias : Mailbox
      errors.add(:local_part, "is already used by #{other == Mailbox ? 'a mailbox' : 'an alias'}") if other.exists?(address: address)
    end
end
