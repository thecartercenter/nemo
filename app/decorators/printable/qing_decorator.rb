module Printable
  class QingDecorator < ::ApplicationDecorator
    delegate_all

    def name_and_rank
      str = "#{full_dotted_rank}. "
      str << h.reqd_sym if required?
      str << name
    end
  end
end
