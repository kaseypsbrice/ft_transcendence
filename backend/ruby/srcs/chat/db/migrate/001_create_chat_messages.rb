require 'active_record'

class CreateChatMessages < ActiveRecord::Migration[7.1]
	def change
		create_table :chat_messages do |t|
			t.integer :sender_id, null: false
			t.integer :receiver_id
			t.text :content, null: false
			t.timestamps default: -> {'now()'}
		end
	end
end
