# frozen_string_literal: true

require "singleton"

module Odk
  # CodeMapper maps between odk codes and form item. Used by odk decorators and odk response parser
  class CodeMapper
    include Singleton

    ITEM_CODE_REGEX = /\A(grp|qing|os|on)([a-f0-9\-]+)/.freeze

    def initialize
    end

    def code_for_item(item, options: {})
      return "/data" if item.is_a?(FormItem) && item.is_root?
      case item
      when Questioning then "qing#{item.id}"
      when QingGroup, Odk::QingGroupFragment then "grp#{item.id}"
      when Subqing
        base = code_for_item(item.questioning)
        if item.multilevel?
          r = options[:previous] ? item.rank - 1 : item.rank
          "#{base}_#{r}"
        else
          base
        end
      when OptionNode then "on#{item.id}"
      when OptionSet then "os#{item.id}"
      end
    end

    def item_id_for_code(code)
      # look for prefix and id, and remove "_#{rank}" suffix for multilevel subqings.
      md = code.match(ITEM_CODE_REGEX)
      raise SubmissionError, "Code format unknown: #{code}." if md.blank? || md.length != 3
      prefix = md[1]
      id = md[2]
      case prefix
      when "grp", "qing" then FormItem.where(id: id).pluck(:id).first
      when "on" then OptionNode.id_to_option_id(id) || OptionNode.old_id_to_option_id(id)
      end
    end

    def item_code?(code)
      code.match?(ITEM_CODE_REGEX)
    end
  end
end
