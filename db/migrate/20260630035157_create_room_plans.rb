class CreateRoomPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :room_plans do |t|
      t.references :design_session, null: false, foreign_key: true
      t.string  :room_key,      null: false
      t.string  :purpose
      t.string  :purpose_label
      t.text    :occupants
      t.boolean :skipped,  null: false, default: false
      t.boolean :complete, null: false, default: false
      t.timestamps
    end
    add_index :room_plans, [ :design_session_id, :room_key ], unique: true
  end
end
