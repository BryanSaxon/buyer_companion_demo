class CreateDesignSelections < ActiveRecord::Migration[8.1]
  def change
    create_table :design_selections do |t|
      t.references :design_session, null: false, foreign_key: true
      t.string  :room_key,       null: false
      t.string  :selection_type, null: false
      t.string  :option_key,     null: false
      t.string  :option_label,   null: false
      t.boolean :pending,        null: false, default: false
      t.timestamps
    end
    add_index :design_selections,
              [ :design_session_id, :room_key, :selection_type ],
              unique: true, name: "idx_design_selections_unique"
  end
end
