module ApplicationHelper

  ERROR_MESSAGE_KEYS_TO_HIDE = {
    :'condition.base' => true
  }

  # hackish way of getting the route key identical to what would be returned by model_name.route_key on a model
  # Should consider merging with ApplicationController's model_class at some point.
  def route_key
    controller.class.name.underscore.gsub("/", "_").gsub(/_controller$/, "")
  end

  # Returns the current action (as symbol), but returns :new for create and :edit for update.
  def canonical_action
    a = controller.action_name.to_sym
    {create: :new, update: :edit}[a] || a
  end

  # pairs flash errors with bootstrap styling
  def bootstrap_flash_class(level)
    case level
      when :notice then "alert alert-info"
      when :success then "alert alert-success"
      when :error then "alert alert-danger"
      when :alert then "alert alert-warning"
      else nil
    end
  end

  # renders an index table for the given class and list of objects
  # options[:within_form] - Whether the table is contained within a form tag. Affects whether a form tag is generated
  #   to contain the batch op checkboxes.
  def index_table(klass, objects, options = {})
    links = []

    unless options[:table_only]
      # get links from class' helper
      links = send("#{klass.model_name.route_key}_index_links", objects).compact

      # if there are any batch links, insert the 'select all' link
      batch_ops = !links.reject{|l| !l.match(/class="batch_op_link"/)}.empty?
      links.insert(0, select_all_link) if batch_ops
    end

    # render, getting fields and checking if there are no objects at all
    render("layouts/index_table",
      :klass => klass,
      :objects => objects,
      :options => options,
      :paginated => objects.respond_to?(:total_entries),
      :links => links.flatten.join.html_safe,
      :fields => send("#{klass.model_name.route_key}_index_fields"),
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

  # wraps the given content in a js tag and a jquery ready handler
  def javascript_doc_ready(&block)
    content = capture(&block)
    javascript_tag("$(document).ready(function(){#{content}});")
  end

  # Converts given object to json and runs through html_safe.
  def json(obj)
    obj.to_json.html_safe
  end

  # takes an array of keys and a scope and builds an options array (e.g. [["Option 1", "opt1"], ["Option 2", "opt2"], ...])
  def translate_options(keys, scope)
    keys.map{|k| [t(k, :scope => scope), k]}
  end

  # translates a boolean value
  def tbool(b)
    t(b ? "common._yes" : "common._no")
  end

  # test if given obj is paginable
  def paginable?(obj)
    obj.respond_to?(:total_pages)
  end

  # if the given array is not paginated, apply an infinite pagination so the will_paginate methods will still work
  def prepare_for_index(objs)
    objs = if !objs.respond_to?(:total_entries) && objs.respond_to?(:paginate)
      objs.paginate(:page => 1, :per_page => 1000000)
    else
      objs
    end

    # ensure .all gets called so that a bunch of extra queries don't get triggered
    objs = objs.all if objs.respond_to?(:all)

    objs
  end

  def translate_model(model)
    pluralize_model(model, :count => 1)
  end

  # gets or constructs the page title from the translation file or from an explicitly set @title
  # returns empty string if no translation found and no explicit title set
  # looks for special :standard option in @title_args, shows seal if set
  # options[:text_only] - don't return any images or html
  def title(options = {})
    # use explicit title if given
    return @title unless @title.nil?

    @title_args ||= {}

    # if action specified outright, use that
    action = if @title_action
      @title_action
    else
      # use 'new' and 'edit' for 'update' and 'create', respectively
      case action_name
      when "update" then "edit"
      when "create" then "new"
      else action_name
      end
    end

    ttl = ''
    model_name = controller_name.classify.downcase

    # Add standard icon if appropriate
    ttl += std_icon(@title_args[:standardized]) unless options[:text_only]

    # Add object type icon where appropriate
    ttl += icon_tag(model_name) unless options[:text_only]

    # add text
    if options[:name_only]
      ttl += @title_args[:name]
    else
      ttl += t(action, {:scope => "page_titles.#{controller_name}", :default => [:all, ""]}.merge(@title_args || {}))
    end

    ttl.html_safe
  end

  def h1_title
    content_tag(:h1, title, class: 'title')
  end

  # pluralizes an activerecord model name
  # assumes 2 if count not given in options
  def pluralize_model(klass, options = {})
    klass = klass.constantize if klass.is_a?(String)
    t("activerecord.models.#{klass.model_name.i18n_key}", :count => options[:count] || 2)
  end

  # translates and interprets markdown markup
  def tmd(*args)
    html = BlueCloth.new(t(*args)).to_html

    if html[0,3] == '<p>' && html[-4,4] == '</p>'
      html = html[3..-5]
    end

    html.html_safe
  end

  # makes sure error messages look right
  def format_validation_error_messages(obj, options = {})
    messages = obj.errors.map do |attrib, message|
      # if error message key is in special list, don't show full message
      ERROR_MESSAGE_KEYS_TO_HIDE[attrib] ? message : obj.errors.full_message(attrib, message)
    end

    # join all messages into one string
    message = messages.join(', ')

    # add a custom prefix if given
    if options[:prefix]
      # remove the inital cap also
      message = options[:prefix] + ' ' + message.gsub(/^([A-Z])/){$1.downcase}
    end

    # add Error: unless in compact mode
    unless options[:compact]
      message = t("common.error", :count => obj.errors.size) + ": " + message
    end

    message
  end

  # makes a set of <li> wrapped links to the index actions of the given classes
  def nav_links(*klasses)
    l = []
    klasses.each do |k|
      if can?(:index, k)
        path = dynamic_path(k, action: :index)
        active = current_page?(path)
        l << content_tag(:li, :class => active ? 'active' : '') do
          link_to(icon_tag(k.model_name.param_key) + pluralize_model(k), path)
        end
      end
    end
    l.join.html_safe
  end
end
