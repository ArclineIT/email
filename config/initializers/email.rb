Rails.application.configure do
  # The mail server's own hostname: what MX records should point at.
  config.x.email.mail_host = ENV.fetch("EMAIL_MAIL_HOST", "mail.arcline.it")
  # HTTP basic auth for the admin area. Required in production.
  config.x.email.username = ENV["EMAIL_ADMIN_USERNAME"].presence
  config.x.email.password = ENV["EMAIL_ADMIN_PASSWORD"].presence
end
