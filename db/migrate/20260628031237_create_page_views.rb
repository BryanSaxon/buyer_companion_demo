class CreatePageViews < ActiveRecord::Migration[8.1]
  def change
    create_table :page_views do |t|
      t.integer :lead_id
      t.string :ip_address
      t.string :city
      t.string :country
      t.string :user_agent
      t.string :event

      t.timestamps
    end
    add_index :page_views, :lead_id
    add_index :page_views, :created_at
  end
end
