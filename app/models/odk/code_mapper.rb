# frozen_string_literal: true

module Odk
  # CodeMapper maps odk codes to form item. Used by odk decorators and odk response parser
  class CodeMapper
    def initialize
    end

    def code_for_item(item)
      return "/data" if item.is_root?
      case item
      when Questioning
        "qing#{item.id}"
      when QingGroup
        "grp#{item.id}"
      end
    end

    # Form passed in because used for fall-back to older qing odk code
    # format that was q#{questioning.question.id}
    def item_id_for_code(code, form)
      clean_code = code.split("_").first # remove suffix for multilevel subqings.
      qing_id = remove_prefix_if_matches(clean_code, "qing")
      return Questioning.where(id: qing_id).pluck(:id).first if qing_id
      grp_id = remove_prefix_if_matches(clean_code, "grp")
      return FormItem.where(id: grp_id).pluck(:id).first if grp_id
      # fallback for older style qing odk code
      question_id = remove_prefix_if_matches(clean_code, "q")
      return Questioning.where(question_id: question_id, form_id: form.id).pluck(:id).first if question_id
      # if we get here, code is not a known format
      raise SubmissionError, "Code format unknown: #{code}."
    end

    private

    def remove_prefix_if_matches(string, prefix)
      md =  string.match(/\A#{Regexp.quote(prefix)}(.+)\z/)
      md.present? && md.length == 2 ? md[1] : nil
    end
  end
end
