# frozen_string_literal: true

module Odk
  # CodeMapper maps between odk codes and form item. Used by odk decorators and odk response parser
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
      # look for prefix and id, and remove "_#{rank}" suffix for multilevel subqings.
      md = code.match(/\A(grp|qing|q|os|on)([a-f0-9\-]+)/)
      raise SubmissionError, "Code format unknown: #{code}." if md.blank? || md.length != 3
      prefix = md[1]
      id = md[2]
      case prefix
      when "grp", "qing" then return FormItem.where(id: id).pluck(:id).first
      # when prefix is q, fallback for older style qing odk code
      when "q" then return Questioning.where(question_id: id, form_id: form.id).pluck(:id).first
      end
    end

    def code_for_option_node_id(node_id)
      "on#{node_id}"
    end

    def option_id_for_code(code)
      node_id = remove_prefix_if_matches(code, "on")
      if node_id
        OptionNode.id_to_option_id(node_id)
      else
        # fallback by looking up other inputs as option ids
        Option.where(id: code).pluck(:id).first
      end
    end

    private

    def remove_prefix_if_matches(string, prefix)
      md =  string.match(/\A#{Regexp.quote(prefix)}(.+)\z/)
      md.present? && md.length == 2 ? md[1] : nil
    end
  end
end
