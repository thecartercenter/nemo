module ApplicationHelper
  def show_flash_and_form_errors(object = nil)
    render("layouts/flash", :flash => flash, :object => object)
  end
  def link_to_if_auth(label, url, action, object = nil, *args)
    authorized?(:action => action, :object => object) ? link_to(label, url, *args) : ""
  end
  # draws a basic form for the given object
  def basic_form(obj, &block)
    form_for(obj) do |f|
      f.mode = controller.action_name.to_sym
      # get the fields spec
      fields = block.call(f)
      # if fields doesn't have sections, create one big section 
      fields = [{:fields => fields}] if fields[0] && fields[0][:col]
      # render the form and return it
      render("layouts/basic_form", :f => f, :fields => fields, :obj => obj)
    end
  end
  def join_links(links, separator = " | ")
    links.reject{|l| l.blank?}.join(separator).html_safe
  end
  def place_field(place, place_lookup)
    render("places/place_field", :place => place, :place_lookup => place_lookup)
  end
  def reqd_sym(condition = true)
    (condition ? '<div class="reqd_sym">*</div>' : '').html_safe
  end
  def action_links(obj, options)
    destroy_warning = options[:destroy_warning] || "Are you sure?"
    klass = obj.class.name.underscore
    links = %w(show edit destroy).collect do |action|
      next if options[action.to_sym] == :exclude
      img = image_tag("#{action}.png")
      key = "#{obj.class.table_name}##{action}"
      case action
      when "show"
        link_to_if_auth(img, send("#{klass}_path", obj), key, obj)
      when "edit"
        link_to_if_auth(img, send("edit_#{klass}_path", obj), key, obj)
      when "destroy"
        link_to_if_auth(img, obj, key, obj, :method => :delete, :confirm => destroy_warning)
      end
    end.compact
    join_links(links, "&nbsp;&nbsp;")
  end
end
