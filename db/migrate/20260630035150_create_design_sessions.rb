class CreateDesignSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :design_sessions do |t|
      t.references :lead, null: false, foreign_key: true, index: { unique: true }
      t.string  :aasm_state,              null: false, default: "welcome"
      t.string  :current_room
      t.integer :current_selection_index, null: false, default: 0
      t.boolean :planning_complete,       null: false, default: false
      t.boolean :style_selected,          null: false, default: false
      t.text    :design_styles
      t.boolean :summary_approved,        null: false, default: false
      t.timestamps
    end
  end
end
