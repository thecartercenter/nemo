class OptionLevel
  include ActiveModel::Serializers::JSON, Translatable

  translates :name

  MAX_NAME_LENGTH = 20

  def initialize(attribs)
    attribs.each{ |k,v| send("#{k}=", v) }
  end

  # For serialization.
  def attributes
    %w(name name_translations).map_hash{ |a| send(a) }
  end

  def as_json(options = {})
    super(root: false)
  end
end
