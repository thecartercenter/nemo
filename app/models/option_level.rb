class OptionLevel
  include Translatable

  translates :name

  def initialize(attribs)
    self.name_translations = attribs[:name_translations]
  end

  def as_json(options = {})
    super(:only => [:name_translations], :methods => :name)
  end
end
