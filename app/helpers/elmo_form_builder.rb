class ElmoFormBuilder < ActionView::Helpers::FormBuilder

  # options[:type] - The type of field to display (:text (default), :check_box, :radio_butons, :textarea, :password, :select, :timezone)
  # options[:required] - Whether the field input is required.
  # options[:content] - The content of the field's main area. If nil, the default content for the field type is used.
  # options[:partial] - A partial to be used as the field's main area. Overrides options[:content].
  # options[:hint] - The hint to be shown for the field. Overrides the default value retrieved from translation file.
  # options[:read_only] - If true, forces field to be displayed as read only. If non-true, this is determined by current action.
  # options[:options] - The set of option tags to be used for a select control.
  # options[:prompt] - The text for the prompt/nil option to be provided in a select control.
  # options[:maxlength] - The maxlength attribute of a text field
  def field(field_name, options = {})
    return hidden_field(field_name) if options[:type] == :hidden

    # options[:read_only] must be true if form_mode is show
    # it may optionally be true if specified by the user
    # else it is false
    options[:read_only] ||= @template.form_mode == :show

    # get key chunks and render partial
    @template.render(:partial => 'layouts/elmo_form_field', :locals => {
      :field_name => field_name,
      :label_tag => elmo_field_label(field_name, options),
      :field_html => elmo_field(field_name, options),
      :hint_html => elmo_field_hint(field_name, options)
    })
  end

  def submit(label = nil, options = {})
    return '' if @template.form_mode == :show

    label ||= :submit

    # if label is a symbol, translate it
    label = I18n.t("common.#{label}") if label.is_a?(Symbol)

    super(label, options)
  end

  private

    # generates html for a form field
    # considers whether field is read_only
    def elmo_field(field_name, options)
      # if partial was specified, just use that
      if options[:partial]

        # add form builder instance and field_name to partial locals
        options[:locals] = {:form => self, :method => field_name}
        @template.render(options.slice(:partial, :locals))

      # else if content was explicitly given, just use that
      elsif options[:content]

        options[:content].html_safe

      # otherwise generate field based on type
      else

        # if field is read only, just show the value
        if options[:read_only]

          # get field value
          val = @object.send(field_name)

          case options[:type]
            when :check_box
              @template.tbool(val)

            when :radio_buttons, :select
              # grab selected option value from options set
              if option = options[:options].find{|o| o[1] == val}
                option[0]
              else
                ""
              end

            when :password
              "*******"

            # show plain field value by default
            else
              val
          end

        else

          case options[:type]
            when :check_box
              check_box(field_name)

            when :radio_buttons
              # build set of radio buttons based on options
              options[:options].map{|o| radio_button(field_name, o, :class => 'radio') + o}.join('&nbsp;&nbsp;').html_safe

            when :textarea
              text_area(field_name)

            when :password
              # add 'text' class for legacy support
              password_field(field_name, :class => 'text')

            when :select
              select(field_name, options[:options], :include_blank => options[:prompt] || true)

            when :timezone
              time_zone_select(field_name)

            # text is the default type
            else
              # add 'text' class for legacy support
              text_field(field_name, {:class => 'text'}.merge(options.slice(:maxlength)))
          end
        end
      end
    end

    # generates html for a field label
    def elmo_field_label(field_name, options)
      label_str = options[:label] || @object.class.human_attribute_name(field_name)
      label_html = label_str + (options[:required] ? " #{@template.reqd_sym}" : "")
      label(field_name, label_html.html_safe, :class => "main")
    end

    # generates html for a field hint block
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

      # if we get this far and hint is still blank, return blank
      if options[:hint].blank?
        ''
      else
        # run the hint text through simple format, but no need to sanitize since we don't want to lose links
        # AND we know this text will not be coming from the user
        @template.simple_format(options[:hint], {}, :sanitize => false)
      end
    end

end