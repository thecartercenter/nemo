# frozen_string_literal: true

# Here we re-open odata_server's main controller
# to do NEMO things like schema overrides.
ODataController.class_eval do # rubocop:disable Metrics/BlockLength
  authorize_resource class: false

  private # rubocop:disable Layout/EmptyLinesAroundAccessModifier

  # This is called automatically by the engine's before_action.
  #
  # The odata engine expects a static schema, but our schema may change
  # whenever forms are updated and also depending on the current mission context.
  def refresh_schema
    namespace = OData::SimpleSchema::NAMESPACE
    schema = OData::ActiveRecordSchema::Base
      .new(namespace, skip_require: true,
                      skip_add_entity_types: true,
                      transformers: {
                        root: ->(*args) { transform_json_for_root(*args) },
                        metadata: ->(*args) { transform_schema_for_metadata(*args) },
                        feed: ->(*args) { transform_json_for_resource_feed(*args) }
                      })

    add_entity_types(schema, distinct_forms)

    ODataController.data_services.clear_schemas
    ODataController.data_services.append_schemas([schema])
  end

  def transform_json_for_root(json)
    trim_context_params(json)
  end

  def transform_schema_for_metadata(_schema)
    OData::SimpleSchema.new(distinct_forms)
  end

  def transform_json_for_resource_feed(json)
    json[:value] = json[:value].map do |response|
      response_id = response["Id"]
      response = Response.find(response_id)
      # Until we have a reliable background job, allow lazy-generating the cached JSON.
      unless response.cached_json
        cached_json = Results::ResponseJsonGenerator.new(response).as_json
        response.update!(cached_json: cached_json)
      end
      response.cached_json
    end
    trim_context_params(json)
  end

  # Trim off URL params; something internally
  # is trying to keep `mode` when generating `metadata_url`.
  def trim_context_params(json)
    json["@odata.context"]&.sub!("?mode=m", "")
    json
  end

  def distinct_forms
    Form
      .accessible_by(current_ability)
      .live
      .where(mission: current_mission)
      .distinct
      .order(:name)
  end

  # Manually add our entity types, grouping responses by form.
  def add_entity_types(schema, distinct_forms)
    distinct_forms.each { |form| add_form_entity_type(schema, form.id, form.name) }
  end

  # Add an entity type to the schema for a given form.
  def add_form_entity_type(schema, id, name)
    name = "Responses: #{name}"

    # We technically should be doing an authorization scope on Responses, but it would not be
    # straightforward so we just rely on the :o_data permissions only being held by roles
    # who can see all responses in a mission.
    entity = schema.add_entity_type(Response, where: {form_id: id},
                                              name: name,
                                              url_name: "Responses-#{id}",
                                              reflect_on_associations: false)

    # We don't want to double-pluralize since it already says "Responses",
    # so override this method.
    def entity.plural_name
      name
    end
  end
end
