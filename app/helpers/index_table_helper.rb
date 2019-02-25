module IndexTableHelper

  # renders an index table for the given class and list of objects
  # options[:omit_form] - Set to true to omit wrapping form tag
  #   to contain the batch op checkboxes.
  def index_table(*args)
    options = args.extract_options!

    klass = args.first || controller.model_class
    objects = args.second || instance_variable_get("@#{klass.name.demodulize.pluralize.underscore}")
    options[:max_actions] ||= 1

    links = []

    unless options[:table_only]
      # get links from class' helper
      links_helper = "#{klass.model_name.route_key}_index_links"
      if respond_to?(links_helper)
        links.concat(send(links_helper, objects).compact)
      end

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
      :links => links.flatten.reduce(:<<),
      :fields => send("#{klass.model_name.route_key}_index_fields"),
      :batch_ops => batch_ops
    )
  end

  def index_row_class(obj, options = {})
    [].tap do |classes|
      method = "#{obj.class.model_name.route_key}_index_row_class"
      classes << send(method, obj) if respond_to?(method)
      classes << 'clickable' if options[:clickable]
    end.compact.join(' ')
  end
end
