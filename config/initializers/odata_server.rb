# frozen_string_literal: true

transform_schema_for_metadata = lambda do |schema|
  schema
end

transform_json_for_resource = lambda do |json|
  json
end

schema = OData::ActiveRecordSchema::Base.new("NEMO", classes: [Response],
                                                     group_by_form: true,
                                                     transform_schema_for_metadata: transform_schema_for_metadata,
                                                     transform_results_for_resource: nil,
                                                     transform_json_for_resource: transform_json_for_resource)
OData::Edm::DataServices.schemas << schema
