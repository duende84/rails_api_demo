class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions do |t|
      t.string :description
      t.string :type
      t.float :amount
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
