Rails.application.routes.draw do
  use_doorkeeper do
    # it accepts :authorizations, :tokens, :token_info, :applications and :authorized_applications
    skip_controllers :applications, :authorized_applications, :authorizations, :token_info
  end

  # module: The Folder
  # path: The URI
  scope module: :api, defaults: { format: :json }, path: 'api' do
    scope module: :v1, path: 'v1' do
      devise_for :users, skip: [:sessions, :password]
      resources :transactions, only: [:index]
    end
  end
end
