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
    options[:read_only] ||= @template.read_only

    # don't render password fields in readonly mode
    return '' if options[:read_only] && options[:type] == :password

    # get object errors (also look under association attrib if field_name ends in _id)
    errors = @object.errors[field_name] + (field_name =~ /^(.+)_id$/ ? @object.errors[$1] : [])

    # get key chunks and render partial
    @template.render(:partial => 'layouts/elmo_form_field', :locals => {
      :field_name => field_name,
      :object_name => @object.class.model_name.param_key,
      :options => options,
      :label_tag => elmo_field_label(field_name, options),
      :field_html => elmo_field(field_name, options) + (options[:append] || ''),
      :hint_html => elmo_field_hint(field_name, options),
      :errors => errors
    })
  end

  def submit(label = nil, options = {})
    return '' if @template.read_only

    label ||= :save

    # if label is a symbol, translate it
    label = I18n.t("common.#{label}") if label.is_a?(Symbol)

    super(label, options)
  end

  def base_errors
    @template.content_tag(:div, @object.errors[:base].join(' '), :class => 'form-errors')
  end

  private

    # generates html for a form field
    # considers whether field is read_only
    def elmo_field(field_name, options)
      # if partial was specified, just use that
      if options[:partial]

        # add form builder instance and field_name to partial locals
        options[:locals] = {:form => self, :method => field_name, :read_only => options[:read_only]}
        @template.render(options.slice(:partial, :locals))

      # else if read only content was explicitly given and form is read only, use that
      elsif options[:read_only] && options[:read_only_content]

        options[:read_only_content].html_safe

      # else if content was explicitly given, just use that
      elsif options[:content]

        options[:content].html_safe

      # otherwise generate field based on type
      else

        # if field is read only, just show the value
        if options[:read_only]

          # get field value
          val = @object.send(field_name)

          # get a human readable version of the value
          human_val = case options[:type]
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

          # render a div with the human val, and embed the real val in a data attrib if it differs
          @template.content_tag(:div, human_val, :class => 'ro-val', :'data-val' => val != human_val ? val : nil)

        else

          placeholder = I18n.t("activerecord.placeholders.#{@object.class.model_name.i18n_key}.#{field_name}", :default => '')
          placeholder = nil if placeholder.blank?

          case options[:type]
            when :check_box
              check_box(field_name)

            when :radio_buttons
              # build set of radio buttons based on options
              options[:options].map{|o| radio_button(field_name, o, :class => 'radio') + o}.join('&nbsp;&nbsp;').html_safe

            when :textarea
              text_area(field_name, {:class => 'form-control', :placeholder => placeholder})

            when :password
              # add 'text' class for legacy support
              password_field(field_name, :class => 'text form-control')

            when :select
              select(field_name, options[:options], {:include_blank => options[:prompt] || true}, {:class => "form-control"})

            when :timezone
              time_zone_select(field_name, nil, {}, {:class => "form-control"})

            # text is the default type
            else
              text_field(field_name, {:class => 'text form-control', :placeholder => placeholder}.merge(options.slice(:maxlength)))
          end
        end
      end
    end

    # generates html for a field label
    def elmo_field_label(field_name, options)
      label_str = options[:label] || @object.class.human_attribute_name(field_name)
      label_html = (options[:required] ? "#{@template.reqd_sym} " : "") + label_str + ":"
      label(field_name, label_html.html_safe, :class => "main")
    end

    # generates html for a field hint block
    def elmo_field_hint(field_name, options)
      return '' if options[:hint] == false

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
        # We also need to be careful not to allow any double quotes as this value will be included in a HTML attrib.
        @template.simple_format(options[:hint], {}, :sanitize => false).gsub('"', "'")
      end
    end

end