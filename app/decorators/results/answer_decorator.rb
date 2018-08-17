# frozen_string_literal: true

module Results
  class AnswerDecorator < ResponseNodeDecorator
    def classes
      "answer form-field qtype-#{qtype_name.dasherize} #{mode_class}"
    end

    def hint
      question_hint = questioning.hint&.chomp(".")&.concat(".")
      drop_hint = h.t("response.drop_hint.#{qtype.name}", default: "").presence
      [question_hint, drop_hint].join(" ")
    end
  end
end
