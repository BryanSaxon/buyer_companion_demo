class AddHouseholdFieldsToDesignSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :design_sessions, :custom_family_json, :text
  end
end
