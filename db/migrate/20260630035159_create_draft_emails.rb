class CreateDraftEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :draft_emails do |t|
      t.references :design_session, null: false, foreign_key: true
      t.text   :original_question, null: false
      t.string :subject,           null: false
      t.text   :body,              null: false
      t.timestamps
    end
  end
end
