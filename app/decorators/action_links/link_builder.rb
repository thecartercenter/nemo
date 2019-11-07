# frozen_string_literal: true

module ActionLinks
  # Builds a list of action links
  class LinkBuilder < ApplicationDecorator
    attr_accessor :object, :actions, :options, :controller

    def initialize(object, actions, **options)
      actions.delete(:edit) if edit_action?
      actions.delete(:show) if show_action?
      self.object = object
      self.actions = actions
      self.options = options
      self.controller = options[:controller] || object.class.model_name.plural
    end

    def to_s
      return nil if object.new_record?
      h.content_tag(:div, class: "top-action-links d-print-none") do
        safe_str << actions.map do |action|
          action, url, method = unpack_action(action)
          next unless url && can?(action, object)
          h.link_to(h.icon_tag(action) << translate_action(action), url,
            method: method, data: {confirm: action == :destroy ? delete_warning : nil},
            class: "#{action.to_s.dasherize}-link")
        end.compact.reduce(:<<)
      end
    end

    private

    # Takes the action params provided and returns a three element array of form [action, url, method]
    def unpack_action(params)
      if params.is_a?(Array)
        if params[1].is_a?(Hash)
          method = params[1][:method] || method_for_action(params[0])
          url = params[1][:url] || url_for_action(params[0], method)
          [params[0], url, method]
        else
          params << method_for_action(params[0])
        end
      else
        [params, url_for_action(params), method_for_action(params)]
      end
    end

    def method_for_action(action)
      case action
      when :destroy then :delete
      when :clone then :put
      end
    end

    def url_for_action(action, method = :get)
      # Include the source action if the method is non-GET as the receiving controller may use it
      # when deciding where to redirect.
      source = method == :get ? nil : h.controller.action_name
      h.url_for(controller: controller, action: action, source: source)
    end

    def translate_action(action)
      t("activerecord.action_links.#{action}",
        default: :"activerecord.action_links.models.#{object.model_name.i18n_key}.#{action}")
    end

    def delete_warning
      description = "#{object.class.model_name.human} '#{object.name}'"
      t("layout.delete_warning", obj_description: description)
    end
  end
end
