class CreateUser
  include Interactor

  def call
    user = User.new(email: context.email, password: context.password)
    if user.save && user.active_for_authentication?
      context.user = user
    else
      context.fail!(message: user.errors)
    end
  end
end
