# frozen_string_literal: true

module OData
  # Wraps a QuestionType for rendering as OData.
  class QuestionType
    attr_accessor :question_type

    delegate :name, to: :question_type

    # Map from QuestionType to OData type.
    ODATA_TYPES = {
      "text" => :string,
      "long_text" => :string,
      "barcode" => :string,
      "integer" => :integer,
      "counter" => :integer,
      "decimal" => :decimal,
      "location" => ENV["NEMO_USE_DATA_FACTORY"].present? ? :string : "#{OData::NAMESPACE}.Geographic",
      "select_one" => :string,
      "multilevel_select_one" => ENV["NEMO_USE_DATA_FACTORY"].present? ? :string : "#{OData::NAMESPACE}.Custom",
      "select_multiple" => ENV["NEMO_USE_DATA_FACTORY"].present? ? :string : [:string],
      "datetime" => :datetime,
      "date" => :date,
      "time" => :time,
      "image" => :string,
      "annotated_image" => :string,
      "signature" => :string,
      "sketch" => :string,
      "audio" => :string,
      "video" => :string
    }.freeze

    def self.odata_type_for(name)
      ODATA_TYPES[name]
    end
  end
end
