class Setting < ActiveRecord::Base
  belongs_to(:settable)
  
  # loads or creates one setting for each settable in the database
  def self.load_and_create
    Settable.all.collect{|sb| sb.setting_or_default}
  end
  
  def self.find_and_update_all(params)
    updated = params.collect{|p| s = find(p[:id]); s.update_attributes(:value => p[:value]); s}
    copy_all_to_config
    updated
  end
  
  def self.copy_all_to_config
    configatron.configure_from_hash(Hash[*load_and_create.collect{|s| [s.settable.key, s.value]}.flatten])
  end
end
