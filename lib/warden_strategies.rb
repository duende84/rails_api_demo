Warden::Strategies.add(:user_strategy) do
  def valid?
    !params[:email].blank? && !params[:password].blank?
  end

  def authenticate!
    user = User.find_for_database_authentication(email: params[:email])
    if user && user.valid_for_authentication? { user.valid_password?(params[:password]) }
      success!(user)
    else
      fail!("Could not log in")
    end
  end
end
