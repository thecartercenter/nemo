# frozen_string_literal: true

module Odk
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
      if /qing\S*/.match? clean_code
        qing_id = clean_code.remove("qing")
        Questioning.where(id: qing_id).pluck(:id).first
      elsif /grp\S*/.match? clean_code
        grp_id = clean_code.remove("grp")
        FormItem.where(id: grp_id).pluck(:id).first
      elsif /q\S*/.match? clean_code # fallback for older style qing odk code
        question_id = clean_code.remove "q"
        Questioning.where(question_id: question_id, form_id: form.id).pluck(:id).first
      else
        raise SubmissionError, "Code format unknown: #{code}."
      end
    end
  end
end
