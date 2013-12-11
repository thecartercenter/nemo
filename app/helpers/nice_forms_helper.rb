# makes a standard looking form
module NiceFormsHelper

  def nice_form_for(obj, options = {})
    options[:html] ||= {}
    options[:html][:class] = "#{obj.class.model_name.singular}_form"
    form = form_for(obj, options) do |f|

      # set form mode
      f.mode = form_mode
      yield(f)
    end

    # add required * def'n
    if form =~ /"reqd_sym"/
      form = (content_tag(:div, t("layout.reqd_sym_definition", :reqd_sym => reqd_sym).html_safe, :class => "tip") + form).html_safe
    end

    form
  end

  # gets the mode a form should be displayed in: one of new, edit, or show
  def form_mode
    {:new => :new, :create => :new, :edit => :edit, :update => :edit, :show => :show}[controller.action_name.to_sym]
  end

  def form_field(f, method, options = {})
    if options[:type] == :hidden
      f.hidden_field(method)
    elsif options[:type] == :submit
      f.submit(f.object.class.human_attribute_name("submit_" + (f.object.new_record? ? "new" : "edit")), :class => "submit")
    else
      # get classes for main div tag
      classes = ["form_field", options[:class]]
      classes << 'stacked' if options[:stacked]
      classes = classes.compact.join(" ")

      # build the main div tag
      content_tag("div", :class => classes, :id => method) do
        label_str = options[:label] || f.object.class.human_attribute_name(method)
        label_html = (label_str + (options[:required] ? " #{reqd_sym}" : "")).html_safe
        label = f.label(method, label_html, :class => "main")

        # temporarily force show mode if requested
        old_f_mode = f.mode
        f.mode = :show if options[:force_show_mode]

        field = content_tag("div", :class => "control") do

          # if this is a partial
          if options[:partial]
            render_options = {:partial => options[:partial]}
            render_options[:locals] = (options[:locals] || {}).merge({:form => f, :method => method})
            render_options[:collection] = options[:collection] if options[:collection]
            render(render_options)
          else
            case options[:type]
            when nil, :text
              f.text_field(method, {:class => "text"}.merge(options.reject{|k,v| ![:size, :maxlength].include?(k)}))
            when :check_box
              # if we are in show mode, show 'yes' or 'no' instead of checkbox
              if f.mode == :show
                content_tag("strong"){tbool(f.object.send(method))}
              else
                f.check_box(method)
              end
            when :radio_buttons
              options[:options].collect{|o| f.radio_button(method, o, :class => "radio") + o}.join("&nbsp;&nbsp;").html_safe
            when :textarea
              f.text_area(method)
            when :password
              f.password_field(method, :class => "text")
            when :country
              country_select(f.object.class.name.downcase, method, nil)
            when :select
              f.select(method, options[:options], :include_blank => options[:blank_text] || true)
            when :datetime
              f.datetime_select(method, :ampm => true, :order => [:month, :day, :year], :default => options[:default])
            when :birthdate
              f.date_select(method, :start_year => Time.now.year - 110, :end_year => Time.now.year - 18,
                :include_blank => true, :order => [:month, :day, :year], :default => nil)
            when :timezone
              f.time_zone_select(method)
            end
          end

        end

        # revert to old form mode
        f.mode = old_f_mode

        # if details text is not given explicitly, look it up
        unless options[:details]

          # get the text based on the method and the form mode
          # we first try the method name plus the form mode,
          # then we try the method name plus 'other'
          # then we try just the method name
          # so for a method called 'name' and form mode 'edit',
          # we'd try activerecord.tips.themodel.name.edit, then .name.other, then just .name
          # if all fail then we return ''
          keys_to_try = [:"#{method}.#{f.mode}", :"#{method}.other", method.to_sym, '']
          options[:details] = t(keys_to_try.first, :scope => [:activerecord, :tips, f.object.class.model_name.i18n_key], :default => keys_to_try.drop(1))

        end

        if options[:details].blank?
          details = ''
        else
          # run the details text through simple format, but no need to sanitize since we don't want to lose links
          # AND we know this text will not be coming from the user
          options[:details] = simple_format(options[:details], {}, :sanitize => false)

          # build the html for the details
          details = content_tag("div", options[:details], :class => "details")
        end

        content_tag(:div, label + field, :class => "label_and_control") +
          details + content_tag("div", "", :class => "space_line")
      end
    end
  end

  def form_submit_button(f = nil, options = {})
    # wrap in form_buttons if not wrapped
    return form_buttons{form_submit_button(f, options.merge(:multiple => true))} unless options[:multiple]
    label = options.delete(:label) || :submit

    # if label is a symbol, translate it
    label = t("common.#{label}") if label.is_a?(Symbol)

    options.merge!(:class => "submit")
    options.delete(:multiple)
    f ? f.submit(label, options) : submit_tag(label, options)
  end

  def form_buttons(options = {}, &block)
    buttons = capture{block.call}
    load_ind = options[:loading_indicator] ? capture{loading_indicator} : ''
    content_tag("div", :class => "form_buttons"){buttons + load_ind + tag("br")}
  end

  # renders the standard 'required' symbol, which is an asterisk
  def reqd_sym(condition = true)
    (condition ? '<div class="reqd_sym">*</div>' : '').html_safe
  end
end