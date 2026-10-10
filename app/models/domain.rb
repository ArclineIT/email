# A domain this mail server accepts mail for.
class Domain < ApplicationRecord
  NAME = /\A([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\z/
  SELECTOR = /\A[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?\z/

  has_many :mailboxes, dependent: :destroy
  has_many :mail_aliases, dependent: :destroy

  normalizes :name, with: ->(name) { name.to_s.strip.downcase.chomp(".") }
  normalizes :catch_all, with: ->(address) { address.to_s.strip.downcase }
  normalizes :dkim_selector, with: ->(selector) { selector.to_s.strip.downcase }

  before_create :generate_dkim_key

  validates :name, presence: true, uniqueness: true, format: { with: NAME, message: "is not a valid domain name" }
  validates :dkim_selector, format: { with: SELECTOR, message: "may only use lowercase letters, digits and hyphens" }
  validates :catch_all, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be an email address" }, allow_blank: true

  scope :ordered, -> { order(:name) }
  scope :active, -> { where(active: true) }

  def generate_dkim_key
    self.dkim_private_key = OpenSSL::PKey::RSA.new(2048).to_pem
  end

  # The public half, as it appears in the DNS record.
  def dkim_public_key
    Base64.strict_encode64(OpenSSL::PKey::RSA.new(dkim_private_key).public_key.to_der)
  end

  def dkim_record_name = "#{dkim_selector}._domainkey.#{name}"
  def dkim_record_value = "v=DKIM1; k=rsa; p=#{dkim_public_key}"

  # What has to be published in DNS for this domain's mail to be delivered and trusted.
  def dns_records(mail_host: Rails.configuration.x.email.mail_host)
    [
      { type: "MX", name: name, value: "10 #{mail_host}." },
      { type: "TXT", name: name, value: "v=spf1 mx -all" },
      { type: "TXT", name: dkim_record_name, value: dkim_record_value },
      { type: "TXT", name: "_dmarc.#{name}", value: "v=DMARC1; p=quarantine; rua=mailto:postmaster@#{name}" }
    ]
  end

  def to_param = name
end
