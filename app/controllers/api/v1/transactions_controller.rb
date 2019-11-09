class Api::V1::TransactionsController < ApplicationController
  def index
    result = GetUserTransactions.call(user: current_user)

    if result.success?
      render json: { data: result.transactions }, status: :ok
    else
      render json: { errors: result.message }, status: :unprocessable_entity
    end
  end
end