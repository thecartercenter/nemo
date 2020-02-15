# frozen_string_literal: true

schema = OData::ActiveRecordSchema::Base.new("NEMO", classes: [Response])
OData::Edm::DataServices.schemas << schema
