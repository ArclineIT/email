class ApplicationController < ActionController::Base
  before_action :restrict_to_modern_browsers
  before_action :require_login

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    # HTTP basic auth from EMAIL_ADMIN_USERNAME and EMAIL_ADMIN_PASSWORD. With neither set
    # the admin area is open, which is only allowed outside production.
    def require_login
      settings = Rails.configuration.x.email

      if settings.username && settings.password
        authenticate_or_request_with_http_basic("arcline-email") do |username, password|
          ActiveSupport::SecurityUtils.secure_compare(username, settings.username) &
            ActiveSupport::SecurityUtils.secure_compare(password, settings.password)
        end
      elsif Rails.env.production?
        render plain: "Set EMAIL_ADMIN_USERNAME and EMAIL_ADMIN_PASSWORD to use the admin area.", status: :service_unavailable
      end
    end

    def restrict_to_modern_browsers
      allow_browser versions: :modern, block: :render_unsupported_browser
    end

    def render_unsupported_browser
      render file: Rails.root.join("public/406-unsupported-browser.html"), layout: false, status: :not_acceptable
    end
end
