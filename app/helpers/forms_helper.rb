# frozen_string_literal: true

# DEPRECATED: Model-related display logic should move to a decorator.
module FormsHelper
  def forms_index_links(_forms)
    links = []
    links << create_link(Form) if can?(:create, Form)
    add_import_standard_link_if_appropriate(links)
    links << link_to(t("action_links.models.form.sms_console"), new_sms_test_path) if can?(:create, Sms::Test)
    links
  end

  def forms_index_fields
    if admin_mode?
      %w[std_icon name updated_at actions]
    else
      %w[std_icon name status downloads responses updated_at actions]
    end
  end

  def format_forms_field(form, field)
    case field
    when "std_icon" then std_icon(form)
    when "name" then link_to(form.name, form.default_path, title: t("common.view"))
    when "status" then form.status_with_icon
    when "questions" then form.questionings.count
    when "updated_at" then l(form.updated_at)
    when "responses"
      if (count = form.responses_count).zero?
        0
      else
        link_to(count, responses_path(search: "form-id:\"#{form.id}\""))
      end
    when "downloads" then form.downloads || 0
    when "smsable" then tbool(form.smsable?)
    when "copy_count" then form.copy_count
    when "allow_incomplete" then tbool(form.allow_incomplete?)
    when "actions"
      links = []
      if can?(:change_status, form)
        links << if form.live?
                   action_link(:pause, pause_form_path(form, source: "index"), method: :patch)
                 else
                   action_link(:go_live, go_live_form_path(form, source: "index"), method: :patch)
                 end
      end
      if can?(:clone, form)
        links << action_link(:clone, clone_form_path(form),
          method: :put, data: {confirm: t("form.clone_confirm", form_name: form.name)})
      end
      if can?(:print, form) # rubocop:disable Style/IfUnlessModifier
        links << action_link(:print, "#", class: "print-link", data: {form_id: form.id})
      end
      if form.smsable? && !admin_mode?
        links << action_link(:sms_guide, sms_guide_form_path(form))
      end
      links
    else form.send(field)
    end
  end

  def forms_index_row_class(form)
    "status-#{form.status}" unless admin_mode?
  end

  def allow_incomplete?
    @form.allow_incomplete?
  end

  # Question types not listed here use PNGs instead of FA icons.
  FORM_ITEM_ICON_CLASSES = {
    "long_text" => "fa-align-left",
    "date" => "fa-calendar",
    "time" => "fa-clock-o",
    "location" => "fa-map-marker",
    "group" => "fa-folder-open-o",
    "image" => "fa-image",
    "sketch" => "fa-pencil-square-o",
    "audio" => "fa-volume-up",
    "video" => "fa-film",
    "counter" => "fa-plus"
  }.freeze

  def form_item_icon(type)
    # Use font awesome icon if defined, else use custom icon from assets dir.
    if cls = FORM_ITEM_ICON_CLASSES[type]
      content_tag(:i, "", class: "fa #{cls} type-icon")
    else
      image_tag("form_items/#{type}.png", class: "type-icon")
    end
  end
end
