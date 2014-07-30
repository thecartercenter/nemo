class OptionLevel
  include Translatable

  translates :name

  def initialize(attribs)
    self.name_translations = attribs[:name_translations]
  end

  def as_json(options = {})
    if options[:for_option_set_form]
      super(:only => [:name_translations], :methods => :name)
    else
      super(options)
    end
  end
end
