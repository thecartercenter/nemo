class ElmoFormBuilder < ActionView::Helpers::FormBuilder

  # options[:type] - The type of field to display (:text, :check_box, :radio_butons, :textarea, :password, :country, :select,
  #   :datetime, :birthdate, :timezone)
  # options[:required] - Whether the field input is required.
  # options[:content] - The content of the field's main area. If nil, the default content for the field type is used.
  # options[:partial] - A partial to be used as the field's main area. Overrides options[:content].
  # options[:hint] - The hint to be shown for the field. Overrides the default value retrieved from translation file.
  # options[:read_only] - If true, forces field to be displayed as read only. If non-true, this is determined by current action.
  # options[:options] - The set of option tags to be used for a select control.
  # options[:prompt] - The text for the prompt/nil option to be provided in a select control.
  # options[:maxlength] - The maxlength attribute of a text field
  def field(field_name, options = {})
    return hidden_field(field_name) if options[:hidden]

    # TODO set options[:read_only]

    # get classes for main div tag
    # TODO id should be better qualified.
    @template.content_tag(:div, :class => 'form_field', :id => field_name) do

      # get label html
      lbl = elmo_field_label(field_name, options)
      fld = ''
      hint = elmo_field_hint(field_name, options)

      # build full string and return
      @template.content_tag(:div, lbl + fld, :class => 'label_and_control') + hint + @template.content_tag(:div, '', :class => 'space_line')
    end

  end

  private

    def elmo_field_label(field_name, options)
      label_str = options[:label] || @object.class.human_attribute_name(field_name)
      label_html = label_str + (options[:required] ? " #{@template.reqd_sym}" : "")
      label(field_name, label_html.html_safe, :class => "main")
    end

    def elmo_field_hint(field_name, options)
      # if hint text is not given explicitly, look it up
      unless options[:hint]
        # get the text based on the field_name and the form mode
        # if field is read_only, we first try the field_name name plus read_only,
        # else we try field_name plus 'editable'
        # then we try just field_name
        # so for a field_name called 'name' in read_only mode,
        # we'd try activerecord.hints.themodel.name.read_only, then just .name
        # if all fail then we return ''
        keys_to_try = [:"#{field_name}.#{options[:read_only] ? 'read_only' : 'editable'}", field_name.to_sym, '']
        options[:hint] = I18n.t(keys_to_try.first, :scope => [:activerecord, :hints, @object.class.model_name.i18n_key], :default => keys_to_try.drop(1))
      end

      # if we get this far and hint is still blank, return no HTML
      if options[:hint].blank?
        ''
      else
        # run the hint text through simple format, but no need to sanitize since we don't want to lose links
        # AND we know this text will not be coming from the user
        options[:hint] = @template.simple_format(options[:hint], {}, :sanitize => false)

        # build the html for the hint
        @template.content_tag("div", options[:hint], :class => "hint")
      end
    end

end