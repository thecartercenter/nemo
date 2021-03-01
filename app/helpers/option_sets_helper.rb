# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module OptionSetsHelper
  def option_sets_index_links(_option_sets)
    links = []
    links << create_link(OptionSet) if can?(:create, OptionSet)
    links << create_link(OptionSets::Import) if can?(:create, OptionSets::Import)
    add_import_standard_link_if_appropriate(links)
    links
  end

  def option_sets_index_fields
    %w[std_icon name options actions]
  end

  def format_option_sets_field(option_set, field)
    case field
    when "std_icon" then std_icon(option_set)
    when "name" then link_to(option_set.name, option_set.default_path, title: t("common.view"))
    when "options"
      # only show the first 3 options as there could be many many
      option_set.options[0...3].collect(&:name).join(", ") + (option_set.options.size > 3 ? ", ..." : "")
    when "questions" then option_set.questions_count
    when "actions"
      # add a clone link if auth'd
      if can?(:clone, option_set)
        confirm_msg = t("option_set.clone_confirm", name: option_set.name)
        [action_link(:clone, clone_option_set_path(option_set),
          title: t("common.clone"), data: {method: "put", confirm: confirm_msg})]
      end
    else option_set.send(field)
    end
  end

  # TODO: These two warning should move inside the IntegrityWarning system, which should probably be
  # renamed to just Warning or FormWarning.
  def multilevel_forbidden_notice
    content_tag(:div, class: "alert alert-warning integrity-warning media") do
      icon_tag("warning") << content_tag(:div, class: "media-body") do
        t("option_set.multilevel_forbidden_notice")
      end
    end
  end

  def huge_notice
    content_tag(:div, class: "alert alert-warning integrity-warning media") do
      icon_tag("warning") << content_tag(:div, class: "media-body") do
        t("option_set.huge_notice", count: number_with_delimiter(@option_set.total_options))
      end
    end
  end
end
