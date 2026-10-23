Rails.application.routes.draw do
  namespace :foreman_arbiter do
    post 'webhook', to: 'webhook_receiver#receive'
    get 'dashboard', to: 'dashboard#index'
  end

  namespace :api, defaults: { format: :json } do
    namespace :v2 do
      scope module: :foreman_arbiter do
        resources :hosts, only: [] do
          member do
            get :attestation, to: 'attestation#show'
          end
        end
      end
    end
  end
end
