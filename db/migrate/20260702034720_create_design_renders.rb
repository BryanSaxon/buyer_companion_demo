class CreateDesignRenders < ActiveRecord::Migration[8.1]
  def change
    create_table :design_renders do |t|
      t.references :design_session, null: false, foreign_key: true
      t.string :room_key, null: false
      t.string :status, default: "pending", null: false
      t.text :prompt

      t.timestamps
    end

    add_index :design_renders, [ :design_session_id, :room_key ], unique: true
  end
end
