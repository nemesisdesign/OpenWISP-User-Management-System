class CreateOproClientApplications < ActiveRecord::Migration
  def self.up
    create_table :opro_client_applications do |t|
      t.string  :name
      t.string  :app_id
      t.string  :app_secret
      t.text    :permissions
      t.timestamps
    end
  end
  
  def self.down
    drop_table :opro_client_applications
  end
end
