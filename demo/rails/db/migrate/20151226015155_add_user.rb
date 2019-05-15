class AddUser < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :name
    end
  end
end
