# frozen_string_literal: true

module OData
  # Initializer for the odata_server engine.
  class Server
    @transform_json_for_root = lambda do |json|
      json
    end

    @transform_schema_for_metadata = lambda do |schema|
      schema
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

      add_entity_types(schema)

      ODataController.data_services.clear_schemas
      ODataController.data_services.append_schemas([schema])
    end

    # Manually add our entity types, grouping responses by form.
    def self.add_entity_types(schema)
      # TODO: Scope to current mission
      forms = Response
        .distinct
        .pluck(:form_id)
        .map { |id| {id: id, name: Form.find(id).name} }

      forms.each { |id:, name:| add_form_entity_type(schema, id, name) }
    end

    # Add an entity type to the schema for a given form.
    def self.add_form_entity_type(schema, id, name)
      name = "Responses: #{name}"
      entity = schema.add_entity_type(Response, where: {form_id: id},
                                                name: name,
                                                reflect_on_associations: false)

      # We don't want to double-pluralize since it already says "Responses",
      # so override this method.
      def entity.plural_name
        name
      end
    end
  end
end

OData::Server.refresh_schema if Settings.odata_api.present? || Rails.env.test?
