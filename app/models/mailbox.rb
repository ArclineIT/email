# A mailbox someone signs in to. The password is stored as bcrypt, which
# Dovecot reads as the BLF-CRYPT scheme.
class Mailbox < ApplicationRecord
  include HasAddress

  MIN_PASSWORD_LENGTH = 10

  has_secure_password

  normalizes :display_name, with: ->(name) { name.to_s.strip }

  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, allow_nil: true
  validates :quota_mb, numericality: { only_integer: true, in: 1..1_000_000 }

  # Where Dovecot keeps this mailbox, relative to the mail root.
  def maildir = "#{domain.name}/#{local_part}/"
end
