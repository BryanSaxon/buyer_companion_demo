class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :company
      t.boolean :approved_render

      t.timestamps
    end
    add_index :leads, :email
  end
end
