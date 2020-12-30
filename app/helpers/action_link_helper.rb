# frozen_string_literal: true

# This file is deprecated. New development should prefer the new ActionLinks::LinkBuilder decorator class.
module ActionLinkHelper
  def translate_action(klass_or_obj, action)
    i18nk = (klass_or_obj.respond_to?(:model_name) ? klass_or_obj : klass_or_obj.class).model_name.i18n_key
    t("action_links.#{action}", default: :"action_links.models.#{i18nk}.#{action}")
  end

  # Generates a link like "Create Option Set" given a klass
  # options[:js] - if true, the link just points to # with expectation that js will bind to it
  def create_link(klass, options = {})
    href = options[:js] ? "#" : dynamic_path(klass, action: :new)
    link_to(translate_action(klass, :new), href, class: "create_#{klass.model_name.param_key}")
  end

  # returns the html for an action icon using font awesome and the mappings defined in IconHelper
  def action_link(action, href, options = {})
    label = t("actions.#{action}")
    options[:class] = Array.wrap(options[:class])
    options[:class] << "action-link" << "action-link-#{action.to_s.dasherize}"
    options[:class] = options[:class].join(" ")
    options[:title] ||= label

    if options.delete(:label) == false
      link_to(icon_tag(action), href, options)
    else
      link_to(icon_tag(action) << label, href, options)
    end
  end

  # creates a link to a batch operation
  def batch_op_link(options)
    link_to(options[:name], "#", data: options.slice(:path, :confirm), class: "batch-link batch-submit-link")
  end
end
