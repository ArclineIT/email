class CreateMailTables < ActiveRecord::Migration[8.1]
  def change
    create_table :domains do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      # Where mail for unknown addresses goes; blank rejects it.
      t.string :catch_all, null: false, default: ""
      t.string :dkim_selector, null: false, default: "arcline"
      t.text :dkim_private_key
      t.timestamps
    end
    add_index :domains, :name, unique: true

    create_table :mailboxes do |t|
      t.references :domain, null: false, foreign_key: { on_delete: :cascade }
      t.string :local_part, null: false
      # The full address, kept in step with local_part so the mail server can look it up directly.
      t.string :address, null: false
      t.string :display_name, null: false, default: ""
      t.string :password_digest, null: false
      t.integer :quota_mb, null: false, default: 1024
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :mailboxes, :address, unique: true

    create_table :aliases do |t|
      t.references :domain, null: false, foreign_key: { on_delete: :cascade }
      t.string :local_part, null: false
      t.string :address, null: false
      # Comma-separated addresses the mail is forwarded to.
      t.text :destinations, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :aliases, :address, unique: true
  end
end
