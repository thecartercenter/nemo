# frozen_string_literal: true

# DEPRECATED: This should all move to an IndexTable decorator, or perhaps ApplicationCollectionDecorator.
module IndexTableHelper
  # renders an index table for the given class and list of objects
  # options[:omit_form] - Set to true to omit wrapping form tag
  #   to contain the batch op checkboxes.
  def index_table(objects, options = {})
    options[:klass] ||= controller.model_class
    options[:max_actions] ||= 1
    links = []

    unless options[:table_only]
      # get links from class' helper
      # DEPRECATED: This should move to a decorator.
      links_helper = "#{options[:klass].model_name.route_key}_index_links"
      links.concat(send(links_helper, objects).compact) if respond_to?(links_helper)

      # if there are any batch links, insert the 'select all' link
      batch_ops = !links.select { |l| l.match(/batch-link/) }.empty?
      links.insert(0, select_all_link) if batch_ops
    end

    # render, getting fields and checking if there are no objects at all
    render("layouts/index_table",
      klass: options[:klass],
      objects: objects,
      options: options,
      paginated: objects.respond_to?(:total_entries),
      links: links.flatten.reduce(:<<),
      fields: send("#{options[:klass].model_name.route_key}_index_fields"),
      batch_ops: batch_ops)
  end

  # creates a link to select all the checkboxes in an index table
  def select_all_link
    link_to(t("layout.select_all"), "#", id: "select-all-link", class: "batch-link")
  end

  def index_row_class(obj, options = {})
    [].tap do |classes|
      method = "#{obj.class.model_name.route_key}_index_row_class"
      classes << send(method, obj) if respond_to?(method)
      classes << "clickable" if options[:clickable]
    end.compact.join(" ")
  end

  def link_divider
    content_tag(:span, "|", class: "link-divider")
  end
end
