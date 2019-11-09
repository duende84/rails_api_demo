class ApplicationController < ActionController::API
  # Doorkeeper code
  before_action :doorkeeper_authorize!
  before_action :current_resource_owner
  respond_to :json

  private

  # Doorkeeper methods
  def current_resource_owner
    if doorkeeper_token
      @current_application = doorkeeper_token.application
      resource_owner_id = doorkeeper_token.resource_owner_id
      @current_user = User.find(resource_owner_id)
    end
  end

  def current_user
    @current_user
  end

  def current_application
    @current_application
  end
end
