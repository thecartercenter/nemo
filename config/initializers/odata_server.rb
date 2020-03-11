# frozen_string_literal: true

schema = OData::ActiveRecordSchema::Base.new("NEMO", classes: [Response], group_by_form: true)
OData::Edm::DataServices.schemas << schema
