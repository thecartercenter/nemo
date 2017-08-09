class QuestionType

  attr_reader :name, :odk_name, :properties

  @@attributes = [
    { name: "text", odk_name: "string", properties: %w(printable smsable textual headerable) },
    { name: "long_text", odk_name: "string", properties: %w(printable smsable textual) },
    { name: "integer", odk_name: "int", properties: %w(printable smsable numeric headerable) },
    { name: "counter", odk_name: "int", properties: %w(printable smsable numeric headerable) },
    { name: "decimal", odk_name: "decimal", properties: %w(printable smsable numeric headerable) },
    { name: "location", odk_name: "geopoint", properties: %w() },
    { name: "select_one", odk_name: "select1", properties: %w(printable has_options smsable headerable) },
    { name: "select_multiple", odk_name: "select", properties: %w(printable has_options smsable headerable) },
    { name: "datetime", odk_name: "dateTime", properties: %w(printable temporal has_timezone smsable headerable) },
    { name: "date", odk_name: "date", properties: %w(printable temporal smsable headerable) },
    { name: "time", odk_name: "time", properties: %w(printable temporal smsable headerable) },
    { name: "image", odk_name: "binary", properties: %w(multimedia) },
    { name: "annotated_image", odk_name: "binary", properties: %w(multimedia) },
    { name: "signature", odk_name: "binary", properties: %w(multimedia printable) },
    { name: "sketch", odk_name: "binary", properties: %w(multimedia printable) },
    { name: "audio", odk_name: "binary", properties: %w(multimedia) },
    { name: "video", odk_name: "binary", properties: %w(multimedia) },
  ]

  # looks up a question type by name
  def self.[](name)
    # build and index the objects if necessary
    @@by_name ||= all.index_by(&:name)

    # return the requested object
    @@by_name[name]
  end

  # returns all question types
  def self.all
    @@all ||= @@attributes.map { |a| new(a) }
  end

  # returns smsable types
  def self.smsable
    @@smsable ||= @@attributes.map { |a| new(a) }.select(&:smsable?)
  end

  def initialize(attribs)
    attribs.each { |k,v| instance_variable_set("@#{k}", v) }
  end

  def human_name
    name.gsub("_", "-")
  end

  # returns whether this is a numeric type
  def numeric?
    properties.include?("numeric")
  end

  # returns whether this is an SMSable type
  def smsable?
    properties.include?("smsable")
  end

  # returns whether this question type makes sense to be printable on a form
  def printable?
    properties.include?("printable")
  end

  # returns whether this question type has options
  def has_options?
    properties.include?("has_options")
  end

  # returns whether this type has a timezone
  def has_timezone?
    properties.include?("has_timezone")
  end

  # returns whether this type is temporal
  def temporal?
    properties.include?("temporal")
  end

  # returns whether this is a textual type
  def textual?
    properties.include?("textual")
  end

  # whether values from this question type is suitable for a table header
  def headerable?
    properties.include?("headerable")
  end

  # whether this is a multimedia type
  def multimedia?
    properties.include?("multimedia")
  end

  def media_type
    case name
    when "image", "annotated_image", "signature", "sketch" then "image"
    when "audio", "video" then name
    else nil
    end
  end
end
