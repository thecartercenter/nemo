class ElmoFormBuilder < ActionView::Helpers::FormBuilder

  # options[:type] - The type of field to display
  #   (:text (default), :check_box, :radio_buttons, :textarea, :password, :select, :timezone, :file)
  # options[:required] - Whether the field input is required.
  # options[:content] - The content of the field's main area. If nil, the default content for the field type is used.
  # options[:partial] - A partial to be used as the field's main area. Overrides options[:content].
  # options[:locals] - Local variables to be used in partial. Should only be used when partial present.
  # options[:hint] - The hint to be shown for the field. Overrides the default value retrieved from translation file.
  # options[:read_only] - If true, forces field to be displayed as read only.
  #   If non-true, this is determined by current action.
  # options[:options] - The set of option tags to be used for a select control.
  # options[:prompt] - The text for the prompt/nil option to be provided in a select control.
  # options[:maxlength] - The maxlength attribute of a text field

  # The placeholder attribute is handled using I18n. See placeholder code below

  def field(field_name, options = {})
    return hidden_field(field_name, options) if options[:type] == :hidden

    # Get form-level read_only value if it's not explicitly given for this field, or if the form_mode is :show.
    # We do not respect the field-level override if form_mode is :show.
    options[:read_only] = read_only? if options[:read_only].nil? || form_mode == :show


    # don't render password fields in readonly mode
    return "" if options[:read_only] && options[:type] == :password

    # get object errors (also look under association attrib if field_name ends in _id)
    errors = @object.errors[field_name] + (field_name =~ /^(.+)_id$/ ? @object.errors[$1] : [])

    # get key chunks and render partial
    @template.render(partial: "layouts/elmo_form_field", locals: {
      field_name: field_name,
      object_name: @object.class.model_name.param_key,
      options: options,
      label_tag: elmo_field_label(field_name, options),
      field_html: elmo_field(field_name, options) + (options[:append] || ""),
      hint_html: elmo_field_hint(field_name, options),
      errors: errors
    })
  end

  def submit(label = nil, options = {})
    # Get form-level read_only value if it's not explicitly given for this field, or if the form_mode is :show.
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
      current = @object.send(field_name)

      # Current value display
      body = @template.content_tag(:span, current || "[#{@template.t('common.none')}]", data: { value: current || "" })

      unless read_only? || options[:no_button] == true
        # Generate/Regenerate button
        data = {
          "handler" => options.delete(:handler) || "#{@template.url_for(@object)}/regenerate_#{field_name}"
        }
        data["confirm"] = options.delete(:confirm) if options[:confirm]

        body += @template.button_tag(@template.t("common.#{current ? 'regenerate' : 'generate'}"),
          class: "regenerate btn btn-default btn-xs", data: data, type: "button")

        # Loading indicator
        body += @template.inline_load_ind(success_failure: true)

        # Backbone view
        body += @template.content_tag(:script,
          "new ELMO.Views.RegenerableFieldView({ el: $('##{field_id}') })".html_safe)
      end

      body
    end

    field(field_name, options)
  end

  def base_errors
    @template.content_tag(:div, @object.errors[:base].join(" "), class: "form-errors")
  end

  def read_only?
    options.has_key?(:read_only) ? options[:read_only] : form_mode == :show
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
      val = @object.send(field_name)

      # if field is read only, just show the value
      if options[:read_only]

        # get a human readable version of the value
        human_val = case options[:type]
        when :check_box
          @template.tbool(val)

        when :radio_buttons, :select
          # grab selected option value from options set
          if option = options[:options].find { |o| o[1].to_s == val }
            option[0]
          else
            ""
          end

        when :file
          val&.original_filename

        when :password
          "*******"

        # show plain field value by default
        else
          val
        end

        # fall back to "[None]" if we have no value to show
        human_val = "[#{@template.t('common.none')}]" if human_val.blank?

        # render a div with the human val, and embed the real val in a data attrib if it differs
        @template.content_tag(:div, human_val, class: "ro-val", :'data-val' => val != human_val ? val : nil)

      else

        placeholder =
          I18n.t("activerecord.placeholders.#{@object.class.model_name.i18n_key}.#{field_name}", default: "")
        placeholder = nil if placeholder.blank?

        case options[:type]
        when :check_box
          check_box(field_name)

        when :radio_buttons
          # build set of radio buttons based on options
          safe_join(
            options[:options].map { |o| radio_button(field_name, o, class: "radio") + o },
            "&nbsp;&nbsp;")

        when :textarea
          text_area(field_name, {class: "form-control", placeholder: placeholder})

        when :password
          # add 'text' class for legacy support
          password_field(field_name, class: "text form-control")

        when :select
          prompt = options[:prompt].nil? ? true : options[:prompt]
          tag_options = {class: "form-control"}
          tag_options[:multiple] = true if options[:multiple]
          select(field_name, options[:options], {include_blank: prompt}, tag_options)

        when :timezone
          time_zone_select(field_name, nil, {}, {class: "form-control"})

        when :file
          file_field(field_name, options.slice(:accept, :disabled, :multiple)) << val&.original_filename

        # text is the default type
        else
          text_field(field_name, {
            class: "text form-control",
            placeholder: placeholder}.merge(options.slice(:maxlength)))
        end
      end
    end
  end

  # generates html for a field label
  def elmo_field_label(field_name, options)
    label_str = options[:label] || @object.class.human_attribute_name(field_name)
    label_html = "".html_safe << (options[:required] ? @template.reqd_sym << " " : "") << label_str << ":"
    label(field_name, label_html, class: "main")
  end

  # generates html for a field hint block
  def elmo_field_hint(field_name, options)
    return "" if options[:hint] == false

    # if hint text is not given explicitly, look it up
    unless options[:hint]
      # get the text based on the field_name and the form mode
      # if field is read_only, we first try the field_name name plus read_only,
      # else we try field_name plus 'editable'
      # then we try just field_name
      # so for a field_name called 'name' in read_only mode,
      # we'd try activerecord.hints.themodel.name.read_only, then just .name
      # if all fail then we return ''
      keys_to_try = [:"#{field_name}.#{options[:read_only] ? "read_only" : "editable"}", field_name.to_sym, ""]
      options[:hint] = I18n.t(keys_to_try.first,
        scope: [:activerecord, :hints, @object.class.model_name.i18n_key],
        default: keys_to_try.drop(1))
    end

    # if we get this far and hint is still blank, return blank
    if options[:hint].blank?
      ""
    else
      # run the hint text through simple format, but no need to sanitize since we don't want to lose links
      # AND we know this text will not be coming from the user
      # We also need to be careful not to allow any double quotes as this value will be included in a HTML attrib.
      @template.simple_format(options[:hint], {}, sanitize: false).gsub('"', "'")
    end
  end
end
