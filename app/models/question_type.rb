class QuestionType

  attr_reader :name, :odk_name, :properties

  @@attributes = [
    {:name => "text", :odk_name => "string", :properties => %w(form_printable smsable textual headerable)},
    {:name => "long_text", :odk_name => "string", :properties => %w(form_printable smsable textual)},
    {:name => "integer", :odk_name => "int", :properties => %w(form_printable smsable numeric headerable)},
    {:name => "decimal", :odk_name => "decimal", :properties => %w(form_printable smsable numeric headerable)},
    {:name => "location", :odk_name => "geopoint", :properties => %w()},
    {:name => "select_one", :odk_name => "select1", :properties => %w(form_printable has_options smsable headerable)},
    {:name => "select_multiple", :odk_name => "select", :properties => %w(form_printable has_options smsable headerable)},
    {:name => "datetime", :odk_name => "dateTime", :properties => %w(form_printable temporal has_timezone smsable headerable)},
    {:name => "date", :odk_name => "date", :properties => %w(form_printable temporal smsable headerable)},
    {:name => "time", :odk_name => "time", :properties => %w(form_printable temporal smsable headerable)}
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
    @@all ||= @@attributes.map{|a| new(a)}
  end

  def initialize(attribs)
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
  end

  def human_name
    name.gsub('_', '-')
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
  def form_printable?
    properties.include?("form_printable")
  end
  alias_method :printable?, :form_printable?

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
end
