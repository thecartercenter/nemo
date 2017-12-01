module Printable
  class QingDecorator < ::ApplicationDecorator
    delegate_all

    def name_and_rank
      str = "#{full_dotted_rank}. "
      str << h.reqd_sym if required?
      str << name
    end

    def question_type
      content = "#{I18n.t("question_type.#{qtype_name}")}:"
      str = h.content_tag(:strong, content)
      str << h.tag(:br)
    end
  end
end
