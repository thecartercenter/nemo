# frozen_string_literal: true


# Here we re-open odata_server's main controller
# to do NEMO things like schema overrides.
ODataController.class_eval do # rubocop:disable Metrics/BlockLength
  authorize_resource class: false

  include FactoryBot::Syntax::Methods

  private # rubocop:disable Layout/EmptyLinesAroundAccessModifier

  # This is called automatically by the engine's before_action.
  #
  # The odata engine expects a static schema, but our schema may change
  # whenever forms are updated and also depending on the current mission context.
  def refresh_schema
    namespace = OData::NAMESPACE
    schema = OData::ActiveRecordSchema::Base
      .new(namespace, skip_require: true,
                      skip_add_entity_types: true,
                      transformers: {
                        root: ->(*args) { transform_json_for_root(*args) },
                        metadata: ->(*args) { transform_schema_for_metadata(*args) },
                        feed: ->(*args) { transform_json_for_collection(*args) },
                        entry: ->(*args) { transform_json_for_entry(*args) }
                      })

    add_entity_types(schema, distinct_forms)

    ODataController.data_services.clear_schemas
    ODataController.data_services.append_schemas([schema])
  end

  def transform_json_for_root(json)
    form = create(:form, name: "Junk #{Random.letters(5)}", question_types: ["select_one", "select_multiple", %w[integer integer]])
    responses =
      # We don't use create_list because that wouldn't create new images each time.
      Array.new(4) do
        create(:response, form: form, answer_values: ["Cat", %w[Cat Dog], [1, 2]])
      end
    scope = Response.where(id: responses.map(&:id))

    Rack::MiniProfiler.step("Destroying") do
      ResponseDestroyer.new(scope: scope).destroy!
    end

    trim_context_params(json)
  end

  def transform_schema_for_metadata(_schema)
    OData::SimpleSchema.new(distinct_forms)
  end

  def transform_json_for_collection(json)
    # The items in the Collection will be Entries, already mapped below.
    trim_context_params(json)
  end

  def transform_json_for_entry(json)
    cached_json = json["CachedJson"]
    # Lazy-cache the JSON if it hasn't been cached yet.
    if cached_json.blank? || ENV["NEMO_FORCE_FRESH_ODATA"].present?
      response = Response.find(json["Id"])
      cached_json = CacheODataJob.cache_response(response)
      # Normally this replacement happens in SQL when querying the data.
      # It's not performant, but this is a fallback for when the JSON hasn't already been cached.
      cached_json = JSON.parse(
        cached_json.to_json.gsub(Results::ResponseJsonGenerator::BASE_URL_PLACEHOLDER, request.base_url)
      )
    end
    cached_json["@odata.context"] = json["@odata.context"] if json["@odata.context"]
    trim_context_params(cached_json)
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
      .published
      .where(mission: current_mission)
      .distinct
      .order(:name)
  end

  # Manually add our entity types, grouping responses by form.
  def add_entity_types(schema, distinct_forms)
    distinct_forms.each { |form| add_form_entity_type(schema, form) }
  end

  # Add an entity type to the schema for a given form.
  def add_form_entity_type(schema, form)
    # We technically should be doing an authorization scope on Responses, but it would not be
    # straightforward so we just rely on the :o_data permissions only being held by roles
    # who can see all responses in a mission.
    old = Results::ResponseJsonGenerator::BASE_URL_PLACEHOLDER
    new = request.base_url
    response = Response
      .where(form_id: form.id)
      .order(created_at: :desc)
      .select("*, replace(cached_json::text, '#{old}', '#{new}')::jsonb AS cached_json")
    entity = schema.add_entity_type(response, name: OData::FormDecorator.new(form).responses_name,
                                              url_name: OData::FormDecorator.new(form).responses_url,
                                              reflect_on_associations: false)

    # We don't want to double-pluralize since it already says "Responses",
    # so override this method.
    def entity.plural_name
      name
    end
  end
end
