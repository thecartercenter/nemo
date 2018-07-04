# frozen_string_literal: true

module Odk
  class CodeMapper

    def initialize
    end

    def code_for_item(item, options = {})
      # puts "get code for #{item.class}: "
      # puts item.id
      return "/data" if item.is_root?
      case item
        when Questioning
          "qing#{item.id}"
        when QingGroup
          "grp#{item.id}"
        # when OptionNode
        #   "on#{item.id}"
      end
    end

    # do fall back here
    def item_id_for_code(code, form)
      code = code.split("_").first   if /\S*_\d/.match? code
      if /qing\S*/.match? code
        qing_id = code.remove("qing")
        Questioning.where(id: qing_id).pluck(:id).first
      elsif /grp\S*/.match? code
        grp_id = code.remove("grp")
        FormItem.where(id: grp_id).pluck(:id).first
      elsif /q\S*/.match? code
        question_id = code.remove "q"
        Questioning.where(question_id: question_id, form_id: form.id).pluck(:id).first
      else
        raise SubmissionError, "Submission contains unknown code format."
      end
    end
  end
end
