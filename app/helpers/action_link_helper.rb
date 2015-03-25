module ActionLinkHelper

  def translate_action(klass_or_obj, action)
    i18nk = (klass_or_obj.respond_to?(:model_name) ? klass_or_obj : klass_or_obj.class).model_name.i18n_key
    t("activerecord.action_links.#{i18nk}.#{action}")
  end

  # Generates a link like "Create New Option Set" given a klass
  # options[:js] - if true, the link just points to # with expectation that js will bind to it
  def create_link(klass, options = {})
    i18nk = klass.model_name.i18n_key
    href = options[:js] ? "#" : dynamic_path(klass, action: :new)
    link_to(translate_action(klass, :new), href, :class => "create_#{klass.model_name.param_key}")
  end

  # Builds links for the action links at the top of a new/edit/show page.
  # If a block is given, appends return value from block to end of div.
  def top_action_links(obj, options = {}, &block)
    options[:except] = Array.wrap(options[:except] || [])
    options[:only] = Array.wrap(options[:only]) unless options[:only].nil?

    options[:controller] ||= obj.class.model_name.plural
    i18nk = obj.class.model_name.i18n_key

    actions_to_show = options[:only] || [:index, :new, :show, :edit, :destroy]
    actions_to_show -= [:new, :show, :edit, :destroy] if canonical_action == :new
    actions_to_show -= options[:except]
    actions_to_show.delete(canonical_action)

    content_tag(:div, :class => 'top-action-links') do
      main_links = actions_to_show.map do |action|
        if can?(action, %w(index new).include?(action) ? obj.class : obj)
          link_to(icon_tag(action) + translate_action(obj, action),
            url_for(controller: options[:controller], action: action),
            method: action == :destroy ? :delete : nil,
            data: {confirm: (action == :destroy) ? delete_warning(obj) : nil},
            class: "#{action}-link")
        end
      end.compact.reduce(:<<)
      (main_links + (block_given? ? capture(&block) : '')).html_safe
    end
  end

  # Assembles links for the basic actions in an index table (edit and destroy)
  def table_action_links(obj, options = {})
    options[:exclude] = Array.wrap(options[:exclude])

    # always exclude edit and destroy if we are in show mode
    options[:exclude] += [:edit, :destroy] if canonical_action == :show

    # build links
    %w(edit destroy).map do |action|

      # skip to next action if action is excluded
      next if options[:exclude].include?(action.to_sym)

      case action
      when "edit"
        # check permissions
        next unless can?(:update, obj)

        # build link
        action_link(action, dynamic_path(obj, action: :edit), :title => t("common.edit"))

      when "destroy"
        # check permissions
        next unless can?(:destroy, obj)

        # build link
        warning = delete_warning(obj, options.slice(:obj_description))
        action_link(action, dynamic_path(obj), :method => :delete, data: {confirm: warning}, :title => t("common.delete"))
      end

    end.reduce(:<<)
  end

  def delete_warning(obj, options = {})
    description = options[:obj_description] || "#{obj.class.model_name.human} '#{obj.name}'"
    t("layout.delete_warning", :obj_description => description)
  end

  # returns the html for an action icon using font awesome and the mappings defined above
  def action_link(action, href, html_options = {})
    # join passed html class (if any) with the default class
    html_options[:class] = [html_options[:class], "action_link", "action_link_#{action}"].compact.join(" ")

    link_to(icon_tag(action), href, html_options)
  end

  # creates a link to a batch operation
  def batch_op_link(options)
    link_to(options[:name], "#",
      :onclick => "batch_submit({path: '#{options[:path]}', confirm: '#{options[:confirm]}'}); return false;",
      :class => "batch_op_link")
  end

  # creates a link to select all the checkboxes in an index table
  def select_all_link
    link_to(t("layout.select_all"), '#', :onclick => "batch_select_all(); return false", :id => 'select_all_link')
  end
end