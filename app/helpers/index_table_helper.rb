module IndexTableHelper

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
