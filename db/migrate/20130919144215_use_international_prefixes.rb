class UseInternationalPrefixes < ActiveRecord::Migration
  def self.up
    remove_column :mobile_prefixes, :international_prefix
    add_column :mobile_prefixes, :name, :string, :limit => 50
    add_column :mobile_prefixes, :code, :string, :limit => 4
  end
  
  def self.down
    add_column :mobile_prefixes, :international_prefix, :number
    remove_column :mobile_prefixes, :name
    remove_column :mobile_prefixes, :code
  end
end
