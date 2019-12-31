class CreateNotificationPrefs < ActiveRecord::Migration[6.0]
  def change
    create_table :notification_prefs do |t|
      t.integer :user_id
      t.string :provider, limit: 20
      t.string :provider_id
      t.string :waiting_confirmation_from
      t.string :optin_type
      t.text :optin_history
      t.timestamps
    end
  end
end
