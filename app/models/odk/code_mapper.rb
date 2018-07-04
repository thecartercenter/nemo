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
    def item_id_for_code(code)
      prefixes = %w[qing grp]
      form_item_id = nil
      code_without_prefix = nil
      prefixes.each do |p|
        if /#{Regexp.quote(p)}\S*/.match?(code)
          code_without_prefix = code.remove p
        end
      end
      if /\S*_\d*/.match?(code)
        form_item_id = code_without_prefix.split("_").first
      else
        form_item_id = code_without_prefix
      end
      form_item_id
    end
  end
end
