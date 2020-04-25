# frozen_string_literal: true

# Here we re-open odata_server's main controller
# to add NEMO things like before_action.
ODataController.class_eval do # rubocop:disable Metrics/BlockLength
  before_action :refresh_schema

  # The odata engine expects a static schema, but our schema may change
  # whenever forms are updated and also depending on the current mission context.
  def refresh_schema
    schema = OData::ActiveRecordSchema::Base
      .new("NEMO", skip_require: true,
                   skip_add_entity_types: true,
                   transformers: {
                     root: ->(*args) { transform_json_for_root(*args) },
                     metadata: ->(*args) { transform_schema_for_metadata(*args) },
                     feed: ->(*args) { transform_json_for_resource_feed(*args) }
                   })

    add_entity_types(schema)

    ODataController.data_services.clear_schemas
    ODataController.data_services.append_schemas([schema])
  end

  def transform_json_for_root(json)
    # Trim off URL params; something internally
    # is trying to keep `mode` when generating `metadata_url`.
    json["@odata.context"].sub!("?mode=m", "")
    json
  end

  def transform_schema_for_metadata(schema)
    schema
  end

  def transform_json_for_resource_feed(json)
    json
  end

  # Manually add our entity types, grouping responses by form.
  def add_entity_types(schema)
    forms = Form
      .live
      .where(mission: current_mission)
      .distinct
      .order(:name)
      .pluck(:id, :name)

    forms.each { |id, name| add_form_entity_type(schema, id, name) }
  end

  # Add an entity type to the schema for a given form.
  def add_form_entity_type(schema, id, name)
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
