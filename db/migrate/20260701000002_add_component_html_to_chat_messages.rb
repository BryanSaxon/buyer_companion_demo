class AddComponentHtmlToChatMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_messages, :component_html, :text
  end
end
