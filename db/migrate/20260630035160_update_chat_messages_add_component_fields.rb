class UpdateChatMessagesAddComponentFields < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_messages, :message_type,   :string, default: "text", null: false
    add_column :chat_messages, :component_type, :string
  end
end
