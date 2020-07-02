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
      "location" => "#{SimpleSchema::NAMESPACE}.Geographic",
      "select_one" => :string,
      "select_multiple" => [:string],
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

    def initialize(question_type)
      self.question_type = question_type
    end

    def odata_type
      ODATA_TYPES[name]
    end
  end
end
