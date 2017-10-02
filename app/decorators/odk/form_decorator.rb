module Odk
  class FormDecorator < FormItemDecorator
    delegate_all

    def default_response_name_instance_tag
      if default_response_name.present?
        content_tag(:meta, tag(:instanceName))
      else
        ""
      end
    end

    def default_response_name_bind_tag
      if default_response_name.present?
        tag(:bind,
          nodeset: "/data/meta/instanceName",
          calculate: DefaultPatternParser.new(default_response_name, src_item: root_group).to_odk,
          readonly: "true()",
          type: "string"
        )
      else
        ""
      end
    end
  end
end
