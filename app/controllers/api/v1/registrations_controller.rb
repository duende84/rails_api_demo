class Api::V1::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  skip_before_action :doorkeeper_authorize!

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    result = SignUpUser.call(email: sign_up_params[:email], password: sign_up_params[:password])

    if result.success?
      render json: { data: result.user }, status: :ok
    else
      render json: { errors: result.message }, status: :unprocessable_entity
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # Overwrite : Devise method
  # Signs in a user on sign up.
  # def sign_up(resource_name, resource)
  #   # Do not sign in user after successfull registration
  #   # sign_in(resource_name, resource)
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   added_attrs = [:email]
  #   devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   added_attrs = [:email]
  #   devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end