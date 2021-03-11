class AddCategoryIdInBills < ActiveRecord::Migration[6.0]
  def change
    add_reference :bills, :category
  end
end
