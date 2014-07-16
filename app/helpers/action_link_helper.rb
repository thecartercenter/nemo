module ActionLinkHelper
  # Builds links for the action links at the top of a new/edit/show page.
  def top_action_links(obj)
    ctlr = obj.class.model_name.plural
    i18nk = obj.class.model_name.param_key
    [:index, :new, :show, :edit, :destroy].map do |action|
      if can?(action, %w(index create).include?(action) ? obj.class : obj) && controller.action_name.to_sym != action
        link_to(t("activerecord.action_links.#{i18nk}.#{action}"),
          url_for(controller: ctlr, action: action),
          method: action == :destroy ? :delete : :get)
      end
    end.compact.join.html_safe
  end

  # Assembles links for the basic actions in an index table (edit and destroy)
  def table_action_links(obj, options)
    route_key = obj.class.model_name.singular_route_key

    options[:exclude] = Array.wrap(options[:exclude])

    # always exclude edit and destroy if we are in show mode
    options[:exclude] += [:edit, :destroy] if controller.action_name == 'show'

    # build links
    %w(edit destroy).map do |action|

      # skip to next action if action is excluded
      next if options[:exclude].include?(action.to_sym)

      case action
      when "edit"
        # check permissions
        next unless can?(:update, obj)

        # build link
        action_link(action, send("edit_#{route_key}_path", obj), :title => t("common.edit"))

      when "destroy"
        # check permissions
        next unless can?(:destroy, obj)

        # build a delete warning
        obj_description = options[:obj_name] ? "#{obj.class.model_name.human} '#{options[:obj_name]}'" : options[:obj_description]
        warning = t("layout.delete_warning", :obj_description => obj_description)

        # build link
        action_link(action, send("#{route_key}_path", obj), :method => :delete, :confirm => warning, :title => t("common.delete"))
      end

    end.join('').html_safe
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