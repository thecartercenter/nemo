module Printable
  class QingDecorator < ::ApplicationDecorator
    delegate_all

    def name_and_rank
      str = "#{full_dotted_rank}. ".html_safe
      str << h.reqd_sym if required?
      str << (name.presence || code)
    end

    def selection_instructions
      content = "#{I18n.t("question_type.#{qtype_name}")}:"
      str = h.content_tag(:strong, content)
      str << h.tag(:br)
    end
  end
end
