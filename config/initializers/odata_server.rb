# frozen_string_literal: true

class SimpleSchema
  attr_reader :namespace, :entity_types

  def initialize
    @namespace = "NEMO"
    @entity_types = SimpleEntities.new
  end
end

class SimpleEntities
  attr_reader :values

  def initialize
    # TODO: All published forms in the missions, regardless of if they have response
    @values = Response.distinct.pluck(:form_id).map do |id|
      name = Form.find(id).name
      SimpleEntity.new("Responses: #{name}")
    end
  end
end

class SimpleEntity
  attr_reader :name, :plural_name, :qualified_name, :key_property, :properties, :navigation_properties

  def initialize(name)
    @name = name
    @plural_name = name
    @qualified_name = name
    @key_property = SimpleProperty.new("Id")
    @properties = {Shortcode: SimpleProperty.new("Shortcode")}
    @navigation_properties = []
  end
end

class SimpleProperty
  attr_reader :name, :return_type

  def initialize(name)
    @name = name
    @return_type = :text
  end

  def nullable?
    true
  end
end

class ODataServer
  @transform_json_for_root = lambda do |json|
    json
  end

  @transform_schema_for_metadata = lambda do |schema|
    SimpleSchema.new
  end

  @transform_json_for_resource_feed = lambda do |json|
    json
  end

  def self.refresh_schema
    schema = OData::ActiveRecordSchema::Base
      .new("NEMO", skip_require: true,
                   skip_add_entity_types: true,
                   transform_json_for_root: @transform_json_for_root,
                   transform_schema_for_metadata: @transform_schema_for_metadata,
                   transform_json_for_resource_feed: @transform_json_for_resource_feed)

    # Manually add our entity types with some extra options.
    # TODO: Clean this up and make more efficient.
    forms = Response.distinct.pluck(:form_id).map { |id| {id: id, name: Form.find(id).name} }
    forms.each do |id:, name:|
      name = "Responses: #{name}"
      entity = schema.add_entity_type(Response, where: {form_id: id},
                                      name: name,
                                      reflect_on_associations: false)
      # We don't want to double-pluralize since it already says "Responses".
      def entity.plural_name
        name
      end
    end

    ODataController.data_services.clear_schemas
    ODataController.data_services.append_schemas([schema])
  end
end

ODataServer.refresh_schema
