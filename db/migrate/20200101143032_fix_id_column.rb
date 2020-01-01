class FixIdColumn < ActiveRecord::Migration[6.0]
  def change
    rename_column :notification_prefs, :provider_id, :provided_id
  end
end
