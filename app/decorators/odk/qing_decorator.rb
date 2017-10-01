module Odk
  class QingDecorator < FormItemDecorator
    delegate_all

    def odk_code
      @odk_code = super
      @odk_code ||= "q#{object.question.id}"
    end

    def has_default?
      default.present? && qtype.defaultable?
    end

    def subqings
      decorate_collection(object.subqings)
    end

    def jr_preload
      case metadata_type
      when "formstart", "formend" then "timestamp"
      else nil
      end
    end

    def jr_preload_params
      case metadata_type
      when "formstart" then "start"
      when "formend" then "end"
      else nil
      end
    end
  end
end
