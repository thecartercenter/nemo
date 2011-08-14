class Setting < ActiveRecord::Base
  belongs_to(:settable)
  
  def self.table_exists?
    ActiveRecord::Base.connection.tables.include?("settings")
  end
  
  # loads or creates one setting for each settable in the database
  def self.load_and_create
    return [] unless table_exists?
    Settable.all.collect{|sb| sb.setting_or_default}
  end
  
  def self.find_and_update_all(params)
    return [] unless table_exists?
    updated = params.collect{|p| s = find(p[:id]); s.update_attributes(:value => p[:value]); s}
    copy_all_to_config
    updated
  end
  
  def self.copy_all_to_config
    return unless table_exists?
    configatron.configure_from_hash(Hash[*load_and_create.collect{|s| [s.settable.key, s.value]}.flatten])
  end
end
