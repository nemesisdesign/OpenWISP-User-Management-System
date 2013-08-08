class CreateOproAccessGrants < ActiveRecord::Migration
  def self.up
    create_table  :opro_access_grants do |t|
      t.string    :code
      t.string    :access_token
      t.string    :refresh_token
      t.text      :permissions
      t.datetime  :access_token_expires_at
      t.integer   :user_id
      t.integer   :application_id

      t.timestamps
    end
  end
  
  def self.down
    drop_table :opro_access_grants
  end
end
