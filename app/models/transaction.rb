class Transaction < ApplicationRecord
  belongs_to :user

  def self.types
    %w(Income Expense)
  end
end

class Income < Transaction; end
class Expense < Transaction; end