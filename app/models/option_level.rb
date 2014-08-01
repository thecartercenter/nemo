class OptionLevel
  include ActiveModel::Serializers::JSON, Translatable

  translates :name

  def initialize(attribs)
    self.name_translations = attribs[:name_translations]
  end

  # For serialization.
  def attributes
    %w(name name_translations).map_hash{ |a| send(a) }
  end

  def as_json(options = {})
    super(root: false)
  end
end
