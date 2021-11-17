# frozen_string_literal: true

class ElmoFormBuilder < ActionView::Helpers::FormBuilder
  # options[:type] - The type of field to display
  #   (:text (default), :check_box, :radio_buttons, :textarea, :password, :select, :timezone, :file, :number)
  # options[:required] - Whether the field input is required.
  # options[:content] - The content of the field's main area.
  #   If nil, the default content for the field type is used.
  # options[:partial] - A partial to be used as the field's main area. Overrides options[:content].
  # options[:locals] - Local variables to be used in partial. Should only be used when partial present.
  # options[:hint] - The hint to be shown for the field.
  #   Overrides the default value retrieved from translation file.
  # options[:read_only] - If true, forces field to be displayed as read only.
  #   If non-true, this is determined by current action.
  # options[:options] - The set of option tags to be used for a select control.
  # options[:prompt] - The text for the prompt/nil option to be provided in a select control.
  # options[:maxlength] - The maxlength attribute of a text field
  # options[:id] - id attribute for tag
  # options[:data] - Data attributes that will be included with input tag
  # options[:unnamed] - Remove the name attribute for the tag so it doesn't show up in the submission data.
  # options[:step] - Step attribute for number fields.
  # options[:value] - Value to use instead of loading from the DB.
  # options[:class] - Class string to append to the field.
  # options[:copyable] - If true, will add 'Copy to Clipboard' button below the field.

  # The placeholder attribute is handled using I18n. See placeholder code below

  def field(field_name, options = {})
    return hidden_field(field_name, options) if options[:type] == :hidden

    # Get form-level read_only value if it's not explicitly given for this field,
    # or if the form_mode is :show.
    # We do not respect the field-level override if form_mode is :show.
    options[:read_only] = read_only? if options[:read_only].nil? || form_mode == :show

    # don't render password fields in readonly mode
    return "" if options[:read_only] && options[:type] == :password

    # get object errors (also look under association attrib if field_name ends in _id)
    id_errors = field_name =~ /^(.+)_id$/ ? @object.errors[Regexp.last_match(1)] : []
    errors = @object.errors[field_name] + id_errors

    wrapper_classes = ["form-field"]
    wrapper_classes << options[:wrapper_class]
    wrapper_classes << "#{@object.class.model_name.param_key}_#{field_name}"
    wrapper_classes << "has-errors" if errors.present?

    if options[:copyable]
      text = I18n.t("layout.copy_to_clipboard")
      options[:id] ||= "copy-value-#{field_name}"
      options[:append] = @template.content_tag(:div, text, class: "btn btn-link btn-a",
                                                           id: "copy-btn-#{field_name}",
                                                           "data-clipboard-target": "##{options[:id]}")
    end

    # get key chunks and render partial
    @template.render(partial: "layouts/elmo_form_field", locals: {
      field_name: field_name,
      options: options,
      wrapper_classes: wrapper_classes.compact.join(" "),
      label_tag: elmo_field_label(field_name, options),
      field_html: elmo_field(field_name, options) + (options[:append] || ""),
      hint_html: elmo_field_hint(field_name, options),
      inline_hint_html: elmo_field_inline_hint(field_name, options),
      errors: errors
    })
  end

  def submit(label = nil, options = {})
    # Get form-level read_only value if it's not explicitly given for this field,
    # or if the form_mode is :show.
    # We do not respect the field-level override if form_mode is :show.
    options[:read_only] = read_only? if options[:read_only].nil? || form_mode == :show

    return "" if options[:read_only]

    label ||= :save

    # if label is a symbol, translate it
    label = I18n.t("common.#{label}") if label.is_a?(Symbol)

    super(label, options)
  end

  def regenerable_field(field_name, options = {})
    field_id = "regenerable-fields-#{SecureRandom.hex}"

    options[:read_only] = true
    options[:read_only_content] = @template.content_tag(:div, id: field_id, class: "regenerable-field") do
      current = options[:initial_value] || @object.send(field_name)
      action = options.delete(:action) || "regenerate_#{field_name}"
      link_i18n_key = options.delete(:link_i18n_key) || (current ? "common.regenerate" : "common.generate")

      # Current value display
      body = @template.content_tag(:span, current || "[#{@template.t('common.none')}]",
        data: {value: current || ""})

      unless read_only? || options[:no_button] == true
        # Generate/Regenerate button
        data = {
          "handler" => options.delete(:handler) ||
            @template.send(:"#{action}_#{@object.model_name.singular_route_key}_path", @object)
        }
        data["confirm-msg"] = options.delete(:confirm) if options[:confirm]

        body << @template.link_to(@template.t(link_i18n_key), "#", class: "regenerate", data: data)
        body << @template.inline_load_ind(success_failure: true)

        # Backbone view
        # rubocop:disable Rails/OutputSafety
        js = "new ELMO.Views.RegenerableFieldView({ el: $('##{field_id}') })".html_safe
        body << @template.content_tag(:script, js)
        # rubocop:enable Rails/OutputSafety
      end

      body
    end

    field(field_name, options)
  end

  def base_errors
    @template.content_tag(:div, @object.errors[:base].join(" "), class: "form-errors")
  end

  def read_only?
    options.key?(:read_only) ? options[:read_only] : form_mode == :show
  end

  def form_mode
    {new: :new, create: :new, show: :show}[@template.controller.action_name.to_sym] || :edit
  end

  private

  # generates html for a form field
  # considers whether field is read_only
  def elmo_field(field_name, options)
    # if partial was specified, just use that
    if options[:partial]

      # add form builder instance and field_name to partial locals
      options[:locals] ||= {}
      options[:locals].merge!(form: self, method: field_name, read_only: options[:read_only])
      @template.render(options.slice(:partial, :locals))

    # else if read only content was explicitly given and form is read only, use that
    elsif options[:read_only] && options[:read_only_content]

      options[:read_only_content]

    # else if content was explicitly given, just use that
    elsif options[:content]

      options[:content]

    # otherwise generate field based on type
    else
      val = options.key?(:value) ? options[:value] : @object.send(field_name)

      # if field is read only, just show the value
      if options[:read_only]

        # get a human readable version of the value
        human_val =
          case options[:type]
          when :check_box
            val = false if val.nil?
            @template.tbool(val)

          when :radio_buttons, :select
            # grab selected option value from options set
            option = options[:options].find { |o| o[1].to_s == val.to_s }
            option ? option[0] : ""

          when :file
            val&.attachment&.filename&.to_s

          when :password
            "*******"

          # show plain field value by default
          else
            val.present? && options[:link] ? @template.link_to(val, options[:link]) : val
          end

        # fall back to "[None]" if we have no value to show
        human_val = "[#{@template.t('common.none')}]" if human_val.blank?

        # render a div with the human val, and embed the real val in a data attrib if it differs
        @template.content_tag(:div, human_val, class: "ro-val", 'data-val': val != human_val ? val : nil)

      else
        # TODO: Ideally, any additional options would pass through to all items
        #   automatically without need to be allowed here explicitly.
        tag_options = options.slice(:id, :data, :checked) # Include these attribs with all tags, if given.

        tag_options[:name] = nil if options[:unnamed]
        tag_options[:class] = "form-control #{options[:class] || ''}".strip

        placeholder_key = "activerecord.placeholders.#{@object.class.model_name.i18n_key}.#{field_name}"
        placeholder = I18n.t(placeholder_key, default: "")
        tag_options[:placeholder] = placeholder if placeholder.present?

        case options[:type]
        when :check_box
          tag_options.delete(:class) # Not sure if this is needed.
          check_box(field_name, tag_options)

        when :radio_buttons
          tag_options[:class] = "radio"
          # build set of radio buttons based on options
          safe_join(
            options[:options].map { |o| radio_button(field_name, o, tag_options) + o },
            "&nbsp;&nbsp;"
          )

        when :textarea
          text_area(field_name, tag_options)

        when :pre
          @template.content_tag(:pre, val, tag_options)

        when :password
          # add 'text' class for legacy support
          tag_options[:class] = "text form-control"
          password_field(field_name, tag_options)

        when :select
          prompt = options[:prompt].nil? ? true : options[:prompt]
          tag_options.merge!(options.slice(:multiple))
          select(field_name, options[:options], {include_blank: prompt}, tag_options)

        when :timezone
          time_zone_select(field_name, nil, {}, tag_options)

        when :file
          tag_options.merge!(options.slice(:accept, :disabled, :multiple))
          file_field(field_name, tag_options) << val&.attachment&.filename&.to_s

        when :number
          tag_options.merge!(options.slice(:step))
          number_field(field_name, tag_options)

        # text is the default type
        else
          # add 'text' class for legacy support
          tag_options[:class] = "text form-control"
          tag_options.merge!(options.slice(:maxlength))
          text_field(field_name, tag_options)
        end
      end
    end
  end

  # generates html for a field label
  def elmo_field_label(field_name, options)
    label_str = options[:label] || @object.class.human_attribute_name(field_name)
    label_html = "".html_safe << (options[:required] ? @template.reqd_sym << " " : "") << label_str
    label(field_name, label_html, class: "main")
  end

  # Generates html for a field hint block.
  # This will be done by default if no hint is specified.
  def elmo_field_hint(field_name, options)
    return "" if options[:hint] == false || (options[:hint].blank? && options[:inline_hint].present?)

    # If hint text is not given explicitly, look it up.
    options[:hint] = options[:hint] ? simple_format_hint(options[:hint]) : hint_text(field_name, options)

    # If we get this far and hint is still blank, return blank.
    options[:hint].presence || ""
  end

  # Generates html for an inline field hint block.
  # This will NOT be done by default if no hint is specified.
  def elmo_field_inline_hint(field_name, options)
    return "" if options[:inline_hint].blank?

    # If hint text is not given explicitly, look it up.
    options[:inline_hint] = hint_text(field_name, options) if options[:inline_hint] == true

    # If we get this far and inline_hint is still blank, return blank.
    # No need to format since it should be a single paragraph.
    options[:inline_hint].presence || ""
  end

  # get the translated, formatted hint text based on the field_name and the form mode.
  #
  # if field is read_only, we first try the field_name name plus read_only,
  # else we try field_name plus 'editable'
  # then we try just field_name
  # so for a field_name called 'name' in read_only mode,
  # we'd try activerecord.hints.themodel.name.read_only, then just .name
  # if all fail then we return ''
  def hint_text(field_name, options)
    keys_to_try = [
      :"#{field_name}.#{options[:read_only] ? "read_only" : "editable"}",
      field_name.to_sym,
      ""
    ]
    @template.t_markdown(keys_to_try.first, scope: [:activerecord, :hints, @object.class.model_name.i18n_key],
                                            default: keys_to_try.drop(1))
  end

  # run the hint text through simple format,
  # but no need to sanitize since we don't want to lose links
  # AND we know this text will not be coming from the user
  # We also need to be careful not to allow any double quotes
  # as this value will be included in a HTML attrib.
  def simple_format_hint(hint)
    @template.simple_format(hint, {}, sanitize: false).tr('"', "'")
  end
end
