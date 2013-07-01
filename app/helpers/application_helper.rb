module ApplicationHelper
  
  FONT_AWESOME_ICON_MAPPINGS = {
    :clone => "copy",
    :destroy => "trash",
    :edit => "edit",
    :map => "globe",
    :print => "print",
    :publish => "arrow-up",
    :sms => "comment",
    :unpublish => "arrow-down"
  }
  
  # renders the flash message and any form errors for the given activerecord object
  def flash_and_form_errors(object = nil)
    render("layouts/flash", :flash => flash, :object => object)
  end
  
  # makes a standard looking form
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
      cls = ["form_field", options[:class]].compact.join(" ")
      content_tag("div", :class => cls, :id => method) do
        label_str = options[:label] || f.object.class.human_attribute_name(method)
        label_html = (label_str + (options[:required] ? " #{reqd_sym}" : "")).html_safe
        label = f.label(method, label_html, :class => "main")
        
        # temporarily force show mode if requested
        old_f_mode = f.mode
        f.mode = :show if options[:force_show_mode]
        
        field = content_tag("div", :class => "form_field_control") do
          
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
        
        tip = t(method, :scope => [:activerecord, :tips, f.object.class.model_name.i18n_key], :default => "")

        details_txt = options[:details] || tip
        details = details_txt.blank? ? "" : content_tag("div", :class => "form_field_details"){simple_format(details_txt)}

        label + field + details + content_tag("div", :class => "space_line"){}
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
  
  # returns the html for an action icon using font awesome and the mappings defined above
  def action_link(action, href, html_options = {})
    # join passed html class (if any) with the default class
    html_options[:class] = [html_options[:class], "action_link"].compact.join(" ")
    
    link_to(content_tag(:i, "", :class => "icon-" + FONT_AWESOME_ICON_MAPPINGS[action.to_sym]), href, html_options)
  end
  
  # assembles links for the basic actions in an index table (show edit and destroy)
  def action_links(obj, options)
    route_key = obj.class.model_name.singular_route_key
    links = %w(edit destroy).collect do |action|
      options[:exclude] = [options[:exclude]] unless options[:exclude].is_a?(Array)
      next if options[:exclude] && options[:exclude].include?(action.to_sym)
      key = "#{obj.class.table_name}##{action}"
      case action
      when "edit"
        can?(:update, obj) ? action_link(action, send("edit_#{route_key}_path", obj), :title => t("common.edit")) : nil
      when "destroy"
        # build a delete warning
        obj_description = options[:obj_name] ? "#{obj.class.model_name.human} '#{options[:obj_name]}'" : options[:obj_description]
        warning = t("layout.delete_warning", :obj_description => obj_description)
        
        can?(:destroy, obj) ? action_link(action, send("#{route_key}_path", obj), :method => :delete, 
          :confirm => warning, :title => t("common.delete")) : nil
      end
    end.compact
    links.join("").html_safe
  end
  
  # creates a link to a batch operation
  def batch_op_link(options)
    button_to(options[:name], "#", 
      :onclick => "batch_submit({path: '#{options[:path]}', confirm: '#{options[:confirm]}'}); return false;",
      :class => "batch_op_link")
  end
  
  # creates a link to select all the checkboxes in an index table
  def select_all_link
    button_to(t("layout.select_all"), "#", :onclick => "batch_select_all(); return false", :id => "select_all_link")
  end
  
  # renders an index table for the given class and list of objects
  def index_table(klass, objects)
    # get links from class' helper
    links = send("#{klass.table_name}_index_links", objects).compact

    # if there are any batch links, insert the 'select all' link
    batch_ops = !links.reject{|l| !l.match(/class="batch_op_link"/)}.empty?
    links.insert(0, select_all_link) if batch_ops
    
    # render, getting fields and checking if there are no objects at all
    render("layouts/index_table",
      :klass => klass,
      :objects => objects,
      :paginated => objects.respond_to?(:total_entries),
      :links => links.flatten.join.html_safe,
      :fields => send("#{klass.table_name}_index_fields"),
      :batch_ops => batch_ops
    )
  end
  
  # renders a loading indicator image wrapped in a wrapper
  def loading_indicator(options = {})
    content_tag("div", :class => "loading_indicator loading_indicator#{options[:floating] ? '_floating' : '_inline'}", :id => options[:id]) do
      image_tag("load-ind-small#{options[:header] ? '-header' : ''}.gif", :style => "display: none", :id => "loading_indicator" + 
        (options[:id] ? "_#{options[:id]}" : ""))
    end
  end
  
  # returns a set of [name, id] pairs for the given objects
  # defaults to using .name and .id, but other methods can be specified, including Procs
  # if :tags is set, returns the <option> tags instead of just the array
  def sel_opts_from_objs(objs, options = {})
    # set default method names
    id_m = options[:id_method] ||= "id"
    name_m = options[:name_method] ||= "name"
    
    # get array of arrays
    arr = objs.collect do |o| 
      # get id and name array
      id = id_m.is_a?(Proc) ? id_m.call(o) : o.send(id_m)
      name = name_m.is_a?(Proc) ? name_m.call(o) : o.send(name_m)
      [name, id]
    end
    
    # wrap in tags if requested
    options[:tags] ? options_for_select(arr) : arr
  end
  
  # renders a collection of objects, including a boilerplate form and calls to the appropriate JS
  def collection_form(params)
    render(:partial => "layouts/collection_form", :locals => params)
  end
  
  # finds the english name of the language with the given code (e.g. 'French' for 'fr')
  # tries to use the translated locale name if it exists, otherwise use english language name from the iso639 gem
  # returns code itself if code not found
  def language_name(code)
    if configatron.locales.include?(code)
      t(:locale_name, :locale => code)
    else
      (entry = ISO_639.find(code.to_s)) ? entry.english_name : code.to_s
    end
  end
  
  # wraps the given content in a js tag and a jquery ready handler
  def javascript_doc_ready(&block)
    content = capture(&block)
    javascript_tag("$(document).ready(function(){#{content}});")
  end
  
  # takes an array of keys and a scope and builds an options array (e.g. [["Option 1", "opt1"], ["Option 2", "opt2"], ...])
  def translate_options(keys, scope)
    keys.map{|k| [t(k, :scope => scope), k]}
  end
  
  # generates a link like "Create New Option Set" given a klass
  # options[:js] - if true, the link just points to # with expectation that js will bind to it
  def create_link(klass, options = {})
    # get the link target path. honor the js option.
    href = options[:js] ? "#" : send("new_#{klass.model_name.singular_route_key}_path")
    
    link_to(t("layout.create_link", :obj => klass.model_name.human, :gender => model_gender(klass)), href,
      :class => "create_#{klass.model_name.param_key}")
  end
  
  # translates a boolean value
  def tbool(b)
    t(b ? "common._yes" : "common._no")
  end
  
  # returns a i18n'd string like "15 Total Users" or "1 published Form".
  # obj - the object name (singular string, e.g. "Submission") or class. if nil, no object name is printed.
  # adj - the adjective to use. the i18n file is searched for this value with the suffix '_adj'. e.g. :total => "total_adj"
  # options
  #   :count - the number of objects. if nil, 1 is assumed for pluralization purposes, but no count is printed.
  #   :titleize - whether to titleize the resulting string
  #   :scope - the i18n scope in which to look
  def obj_with_adj(obj, adj, options = {})
    # assume 1 if no count given
    options[:count] ||= 1
    
    # get the appropriate object name string
    # if it's already a string, pluralize it using the inflector
    objs = if obj.is_a?(String)
      pluralize_without_count(options[:count], obj)
    # if we have an activerecord class, pluralize it using the :count mechanism
    elsif obj.respond_to?(:model_name)
      t("activerecord.models.#{obj.model_name.i18n_key}", :count => options[:count])
    else
      ""
    end
    
    str = t("#{adj}_adj",
      :count => options[:count],
      :objs => objs,
      :scope => options[:scope] || "layout")
      
    # add the <strong> tag
    str.gsub!(/\b(\d+)\b/, "<strong>\\1</strong>")
    
    # titleize if requested
    str = str.titleize if options[:titleize]
    
    # remove extraneous spaces
    str.gsub(/\s\s+/, " ").html_safe
  end
  
  # pluralizes a word based on count but doesn't print count
  def pluralize_without_count(count, noun, text = nil)
    count == 1 ? "#{noun}#{text}" : "#{noun.pluralize}#{text}"
  end
  
  # if the given array is not paginated, apply an infinite pagination so the will_paginate methods will still work
  def ensure_paginated(objs)
    if !objs.respond_to?(:total_entries) && objs.respond_to?(:paginate)
      objs.paginate(:page => 1, :per_page => 1000000)
    else
      objs
    end
  end
  
  def translate_model(model)
    pluralize_model(model, :count => 1)
  end
  
  # looks up a model's gender. may be nil
  def model_gender(klass)
    t("activerecord.models.#{klass.model_name.param_key}.gender", :default => nil)
  end
end
