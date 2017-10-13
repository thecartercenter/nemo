module ApplicationHelper

  ERROR_MESSAGE_KEYS_TO_HIDE = {
    :'condition.base' => true
  }

  # Builds a URL with the exact given path based on the system's host, protocol, and port.
  def url_for_path(path)
    path = "/#{path}" if path[0] != "/"
    URI::HTTP.build(configatron.url.to_h.merge(path: path))
  end

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

  def alerts(hash)
    hash.map do |name, msg|
      # Only echo valid message types
      if css_class = bootstrap_flash_class(name)
        content_tag(:div, class: css_class) do
          content_tag(:strong, t("flash_message_types.#{name}")) << ": " << msg
        end
      end
    end.compact.reduce(:<<)
  end

  # pairs flash errors with bootstrap styling
  def bootstrap_flash_class(level)
    case level.to_sym
    when :notice then "alert alert-info"
    when :success then "alert alert-success"
    when :error then "alert alert-danger"
    when :alert then "alert alert-warning"
    end
  end

  # renders a loading indicator image wrapped in a wrapper
  def loading_indicator(options = {})
    floating = options[:floating] ? "_floating" : "_inline"
    content_tag("div", class: "loading_indicator loading_indicator#{floating}", id: options[:id]) do
      body = image_tag("load-ind-small#{options[:header] ? '-header' : ''}.gif",
        style: "display: none",
        id: "loading_indicator" + (options[:id] ? "_#{options[:id]}" : ""))

      if options[:success_failure]
        body += content_tag("i", "", class: "success fa fa-fw fa-check-circle", style: "display: none")
        body += content_tag("i", "", class: "failure fa fa-fw fa-minus-circle", style: "display: none")
      end

      body
    end
  end

  # returns a set of [name, id] pairs for the given objects
  # defaults to using .name and .id, but other methods can be specified, including Procs
  # if :tags is set, returns the <option> tags instead of just the array
  def sel_opts_from_objs(objs, options = {})
    objs = Array.wrap(objs)

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

  # google maps
  def javascript_google_maps
    if configatron.has_key(:google_maps_api_key)
      api_key = configatron.google_maps_api_key
      javascript_include_tag("https://maps.googleapis.com/maps/api/js?key=#{api_key}&v=3")
    end
  end

  # Converts given object/value to json and runs through html_safe.
  # In Rails 4, this is necessary and sufficient to guard against XSS in JSON.
  def json(obj)
    obj.to_json.html_safe
  end

  # takes an array of keys and a scope and builds an options array
  # e.g. [["Option 1", "opt1"], ["Option 2", "opt2"], ...]
  def translate_options(keys, scope)
    keys.map { |k| [t(k, scope: scope), k] }
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
    if !objs.respond_to?(:total_entries) && objs.respond_to?(:paginate)
      objs.paginate(page: 1, per_page: 1000000)
    else
      objs
    end
  end

  def translate_model(model)
    pluralize_model(model, count: 1)
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

    "".html_safe.tap do |ttl|
      model_name = controller_name.classify.downcase

      # Add standard icon if appropriate
      ttl << std_icon(@title_args[:standardized]) unless options[:text_only]

      # Add object type icon where appropriate
      ttl << icon_tag(model_name) unless options[:text_only]

      # add text
      if options[:name_only]
        ttl << @title_args[:name]
      else
        ttl << t(action, {scope: "page_titles.#{controller_name}", default: [:all, ""]}.merge(@title_args || {}))
      end
    end
  end

  def h1_title
    content_tag(:h1, title, class: "title")
  end

  # pluralizes an activerecord model name
  # assumes 2 if count not given in options
  def pluralize_model(klass, options = {})
    klass = klass.constantize if klass.is_a?(String)
    t("activerecord.models.#{klass.model_name.i18n_key}", count: options[:count] || 500)
  end

  # Translates and interprets markdown style translations.
  # Escapes HTML in any arguments.
  def tmd(key, options = {})
    options.keys.each { |k| options[k] = html_escape(options[k]).to_s unless %w(default scope).include?(k.to_s) }

    html = BlueCloth.new(t(key, options)).to_html

    # Remove surrounding <p> tags if present.
    html = html[3..-5] if html[0,3] == "<p>" && html[-4,4] == "</p>"

    # We can safely do this because we control what's in the translation file
    # and we've escaped the options.
    html.html_safe
  end

  # makes sure error messages look right
  def format_validation_error_messages(obj, options = {})
    messages = obj.errors.map do |attrib, message|
      # if error message key is in special list, don't show full message
      ERROR_MESSAGE_KEYS_TO_HIDE[attrib] ? message : obj.errors.full_message(attrib, message)
    end

    # join all messages into one string
    message = messages.join(", ")

    # add a custom prefix if given
    if options[:prefix]
      # remove the inital cap also
      message = options[:prefix] + " " + message.gsub(/^([A-Z])/) { $1.downcase }
    end

    # add Error: unless in compact mode
    message = t("common.error", count: obj.errors.size) + ": " + message unless options[:compact]


    message
  end

  # pill label
  def pill_label(text, kind: "default")
    content_tag(:span, text, class: "label label-#{kind}")
  end

  # makes a set of <li> wrapped links to the index actions of the given classes
  def nav_links(*klasses)
    links = []
    klasses.each do |k|
      if can?(:index, k)
        path = dynamic_path(k, action: :index)
        active = current_page?(path)
        links << content_tag(:li, class: active ? "active" : "") do
          link_to(icon_tag(k.model_name.param_key) + pluralize_model(k), path)
        end
      end
    end
    links.reduce(:<<)
  end

  def conditional_tag(name, condition, options = {}, &block)
    if condition
      content_tag(name, options) { capture(&block) }
    else
      capture(&block)
    end
  end
end
