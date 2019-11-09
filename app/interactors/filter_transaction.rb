class FilterTransaction
  include Interactor

  def call
    context.transactions = context.user.transactions
  end
end
