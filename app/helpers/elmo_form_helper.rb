# frozen_string_literal: true

# makes a standard looking form
module ElmoFormHelper
  # renders a form using the ElmoFormBuilder
  def elmo_form_for(obj, *args, &block)
    options = args.extract_options!
    general_class = options[:override_class] || "elmo-form"
    specific_class = "#{obj.class.model_name.singular}_form"
    defaults = {
      builder: ElmoFormBuilder,
      html: {
        class: "#{general_class} #{specific_class}"
      }
    }

    # Deep merge the user-provided options with the defaults
    args << merge_options(defaults, options)

    # Init code for the generic view that manages the form hints.
    hint_view = javascript_tag("$(function() { new ELMO.Views.FormHintView() })")

    form_for(obj, *args, &block) << hint_view
  end

  # renders a set of form fields using the ElmoFormBuilder
  def elmo_fields_for(field_name, obj, *args, &block)
    defaults = {
      builder: ElmoFormBuilder
    }

    # deep merge the user-provided options with the defaults;
    args << merge_options(defaults, args.extract_options!)

    fields_for(field_name, obj, *args, &block)
  end

  # gets the mode a form should be displayed in: one of new, edit, or show
  def form_mode
    {new: :new, create: :new, show: :show}[controller.action_name.to_sym] || :edit
  end

  # Tests if form_mode == :show. Note that some the ElmoFormBuilder overrides
  # form_mode when rendering custom partials
  # using the :partial directive. This is also why a ? is not used as a suffix.
  def read_only
    form_mode == :show
  end

  # renders the standard 'required' symbol, which is an asterisk
  def reqd_sym
    content_tag(:div, "*", class: "reqd-sym")
  end

  # Renders a hint wrapper and link that displays a popover. Note that an instance of FormHintView must exist
  # and be covering this element for the popover to work.
  # Default link content is the question mark icon, but can be overridden.
  # If content is blank, returns an empty wrapper.
  def hint_popover(content, link: nil)
    content_tag(:div, class: "hint-wrapper") do
      if content.blank?
        ""
      else
        link ||= content_tag(:i, "", class: "hint fa fa-2x fa-info-circle")
        content_tag(:a, link, tabindex: -1, role: "button", class: "hint",
                              "data-trigger": "manual", "data-toggle": "popover",
                              "data-content": content)
      end
    end
  end

  private

  def merge_options(defaults, options)
    defaults.deep_merge(options) do |key, oldval, newval|
      # if the key is :class, merge the old and new values into a space-separated list
      key == :class ? "#{oldval} #{newval}" : newval
    end
  end
end
