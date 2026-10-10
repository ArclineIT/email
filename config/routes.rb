Rails.application.routes.draw do
  root "domains#index"

  # Domain names contain dots, so the format comes from the Accept header instead
  # of a file extension.
  resources :domains, param: :name, except: %i[ new edit ], format: false, constraints: { name: %r{[^/]+} } do
    member do
      post :check_dns
      post :rotate_dkim
    end
    resources :mailboxes, only: %i[ create update destroy ]
    resources :mail_aliases, path: "aliases", only: %i[ create update destroy ]
  end

  # Health check for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
