# frozen_string_literal: true

class QuestionType
  AVAILABLE_PROPERTIES = %w[printable smsable textual headerable defaultable numeric
                            multimedia temporal has_options has_timezone refable
                            lastpreloadable reportable].freeze
  attr_reader :name, :odk_name, :properties

  @attributes = [{
    name: "text",
    odk_name: "string",
    properties: %w[printable smsable textual headerable defaultable refable lastpreloadable reportable]
  }, {
    name: "long_text",
    odk_name: "string",
    properties: %w[printable smsable textual refable lastpreloadable defaultable reportable]
  }, {
    name: "barcode",
    odk_name: "barcode",
    properties: %w[printable smsable textual refable lastpreloadable reportable]
  }, {
    name: "integer",
    odk_name: "int",
    properties: %w[printable smsable numeric headerable refable lastpreloadable defaultable reportable]
  }, {
    name: "counter",
    odk_name: "int",
    properties: %w[printable smsable numeric headerable refable lastpreloadable defaultable reportable]
  }, {
    name: "decimal",
    odk_name: "decimal",
    properties: %w[printable smsable numeric headerable refable lastpreloadable defaultable reportable]
  }, {
    name: "location",
    odk_name: "geopoint",
    properties: %w[reportable lastpreloadable]
  }, {
    name: "select_one",
    odk_name: "select1",
    properties: %w[printable has_options smsable headerable refable lastpreloadable reportable]
  }, {
    name: "select_multiple",
    odk_name: "select",
    properties: %w[printable has_options smsable headerable refable lastpreloadable reportable]
  }, {
    name: "datetime",
    odk_name: "dateTime",
    properties: %w[printable temporal has_timezone smsable headerable refable
                   lastpreloadable defaultable reportable]
  }, {
    name: "date",
    odk_name: "date",
    properties: %w[printable temporal smsable headerable refable lastpreloadable defaultable reportable]
  }, {
    name: "time",
    odk_name: "time",
    properties: %w[printable temporal smsable headerable refable lastpreloadable defaultable reportable]
  }, {
    name: "image",
    odk_name: "binary",
    properties: %w[multimedia]
  }, {
    name: "annotated_image",
    odk_name: "binary",
    properties: %w[multimedia]
  }, {
    name: "signature",
    odk_name: "binary",
    properties: %w[multimedia printable]
  }, {
    name: "sketch",
    odk_name: "binary",
    properties: %w[multimedia printable]
  }, {
    name: "audio",
    odk_name: "binary",
    properties: %w[multimedia]
  }, {
    name: "video",
    odk_name: "binary",
    properties: %w[multimedia]
  }]

  # looks up a question type by name
  def self.[](name)
    # build and index the objects if necessary
    @by_name ||= all.index_by(&:name)

    # return the requested object
    @by_name[name.to_s]
  end

  # returns all question types
  def self.all
    @all ||= @attributes.map { |a| new(a) }
  end

  def self.with_property(property)
    all.select(&:"#{property}?")
  end

  def initialize(attribs)
    attribs.each { |k, v| instance_variable_set("@#{k}", v) }
  end

  def human_name
    name.tr("_", "-")
  end

  # Defines methods for checking whether this type has a certain property
  # for example:
  #  def numeric?
  #    properties.include?("numeric")
  #  end
  AVAILABLE_PROPERTIES.each do |property|
    define_method "#{property}?" do
      properties.include?(property)
    end
  end

  # Defines boolean methods for checking type name.
  @attributes.each do |attrib|
    define_method "#{attrib[:name]}?" do
      name == attrib[:name]
    end
  end

  def media_type
    case name
    when "image", "annotated_image", "signature", "sketch" then "image"
    when "audio", "video" then name
    end
  end
end
