class Option < ActiveRecord::Base
  has_many(:option_sets, :through => :option_settings)
  has_many(:option_settings)
  
  def name(lang = nil)
    Translation.lookup(self.class.name, id, 'name', lang)
  end
end
