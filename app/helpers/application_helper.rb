# ELMO - Secure, robust, and versatile data collection.
# Copyright 2011 The Carter Center
#
# ELMO is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# ELMO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with ELMO.  If not, see <http://www.gnu.org/licenses/>.
# 
module ApplicationHelper

  # renders the flash message and any form errors for the given activerecord object
  def flash_and_form_errors(object = nil)
    render("layouts/flash", :flash => flash, :object => object)
  end
  
  # applies any customizations to automatically generated form error messages
  # called from layouts/flash
  def fix_error_messages(msgs)
    msgs.gsub!("Answers are invalid", "One or more answers are invalid")
    msgs.gsub!("@ please.", "@")
    msgs.gsub!("look like an email address.", "look like an email address")
    msgs
  end
  
  # renders a link only if the current user is authorized for the specified action
  def link_to_if_auth(label, url, action, object = nil, *args)
    authorized?(:action => action, :object => object) ? link_to(label, url, *args) : ""
  end
  
  # same as link_to_if_auth but for button_to
  def button_to_if_auth(label, url, action, object = nil, *args)
    authorized?(:action => action, :object => object) ? button_to(label, url, *args) : ""
  end
  
  # draws a basic form for the given object
  def basic_form(obj, &block)
    form_for(obj) do |f|
      f.mode = controller.action_name.to_sym
      # get the fields spec
      spec = block.call(f)
      # if fields doesn't have sections, create one big section 
      spec[:sections] = [{:fields => spec[:fields]}] unless spec[:sections]
      # render the form and return it
      render("layouts/basic_form", :f => f, :spec => spec, :obj => obj)
    end
  end
  
  # joins a set of links together with pipe characters, ignoring any blank ones
  # for use with link_to_if_auth
  def join_links(*links)
    links.reject{|l| l.blank?}.join(" | ").html_safe
  end
  
  # renders a place field in a form
  def place_field(form)
    render("places/place_field", :form => form)
  end
  
  # renders the standard 'required' symbol, which is an asterisk
  def reqd_sym(condition = true)
    (condition ? '<div class="reqd_sym">*</div>' : '').html_safe
  end
  
  # assembles links for the basic actions in an index table (show edit and destroy)
  def action_links(obj, options)
    destroy_warning = options[:destroy_warning] || "Are you sure?"
    klass = obj.class.name.underscore
    links = %w(show edit destroy).collect do |action|
      options[:exclude] = [options[:exclude]] unless options[:exclude].is_a?(Array)
      next if options[:exclude] && options[:exclude].include?(action.to_sym)
      img = image_tag("#{action}.png")
      key = "#{obj.class.table_name}##{action}"
      case action
      when "show"
        link_to_if_auth(img, send("#{klass}_path", obj), key, obj, :title => "View")
      when "edit"
        link_to_if_auth(img, send("edit_#{klass}_path", obj), key, obj, :title => "Edit")
      when "destroy"
        link_to_if_auth(img, obj, key, obj, :method => :delete, :confirm => destroy_warning, :title => "Delete")
      end
    end.compact
    links.join("").html_safe
  end
  
  # creates a link to a batch operation
  # options include :action (e.g. forms#add_questions), :id, :format, :name (name of the link)
  def batch_op_link(options)
    url_bits = {}
    url_bits[:controller], url_bits[:action] = options[:action].split("#")
    url_bits[:id] = options[:id] if options[:id]
    url_bits[:format] = options[:format] if options[:format]
    path = url_for(url_bits)
    button_to_if_auth(options[:name], "#", options[:action], nil, 
      :onclick => "batch_submit({path: '#{path}', confirm: '#{options[:confirm]}'}); return false;",
      :class => "batch_op_link")
  end
  
  # creates a link to select all the checkboxes in an index table
  def select_all_link
    button_to("Select All", "#", :onclick => "batch_select_all(); return false", :id => "select_all_link")
  end
  
  # renders an index table for the given class and list of objects
  def index_table(klass, objects)
    # figure out of we're dealing with a pagination collection or just a normal array
    paginated = objects.is_a?(WillPaginate::Collection) && 
      objects.total_entries != 0 && objects.total_entries > objects.size
    
    # get links from class' helper
    links = send("#{klass.table_name}_index_links", objects)
    # if there are any batch links, insert the 'select all' link
    batch_ops = !links.reject{|l| !l.match(/class="batch_op_link"/)}.empty?
    links.insert(0, select_all_link) if batch_ops
    
    # render, getting fields and checking if there are no objects at all
    render("layouts/index_table",
      :klass => klass,
      :objects => objects,
      :links => join_links(*links.flatten),
      :paginated => paginated,
      :human_class_name => klass.name.underscore.humanize.downcase,
      :fields => send("#{klass.table_name}_index_fields"),
      :batch_ops => batch_ops
    )
  end
end
