module FormsHelper
  def forms_index_links(forms)
    links = []

    # add links based on authorization
    links << create_link(Form) if can?(:create, Form)
    links << link_to(t("page_titles.sms_tests.all"), new_sms_test_path) if can?(:create, Sms::Test)

    add_import_standard_link_if_appropriate(links)

    # return links
    links
  end

  def forms_index_fields
    if admin_mode?
      %w(std_icon name updated_at actions)
    else
      %w(std_icon version name published downloads responses smsable allow_incomplete updated_at actions)
    end
  end

  def format_forms_field(form, field)
    case field
    when "std_icon" then std_icon(form)
    when "version" then form.version
    when "name" then link_to(form.name, form_path(form), title: t("common.view"))
    when "questions" then form.questionings_count
    when "updated_at" then l(form.updated_at)
    when "responses"
      form.responses_count == 0 ? 0 :
        link_to(form.responses_count, responses_path(search: "form:\"#{form.name}\""))
    when "downloads" then form.downloads || 0
    when "published" then tbool(form.published?)
    when "smsable" then tbool(form.smsable?)
    when "copy_count" then form.copy_count
    when "allow_incomplete" then tbool(form.allow_incomplete?)
    when "actions"
      # get standard action links
      table_action_links(form).tap do |links|

        # get the appropriate publish icon and add link, if auth'd
        if can?(:publish, form)
          verb = form.published? ? "unpublish" : "publish"
          links << action_link(verb, publish_form_path(form), title: t("form.#{verb}"), :'data-method' => 'put')
        end

        # add a clone link if auth'd
        if can?(:clone, form)
          links << action_link("clone", clone_form_path(form), :'data-method' => 'put',
            title: t("common.clone"), data: {confim: t("form.clone_confirm")}, form_name: form.name)
        end

        # add a print link if auth'd
        if can?(:print, form)
          links << action_link("print", "#", title: t("common.print"), class: 'print-link', :'data-form-id' => form.id)
        end

        # add an sms template link if appropriate
        if form.smsable? && form.published? && !admin_mode?
          links << action_link("sms", sms_guide_form_path(form), title: "SMS Guide")
        end

        # add a loading indicator
        links << loading_indicator(id: form.id, floating: true)
      end
    else form.send(field)
    end
  end

  def allow_incomplete?
    @form.allow_incomplete? && @style != 'commcare'
  end

  # Question types not listed here use PNGs instead of FA icons.
  FORM_ITEM_ICON_CLASSES = {
    'long_text' => 'fa-align-left',
    'date' => 'fa-calendar',
    'time' => 'fa-clock-o',
    'location' => 'fa-map-marker',
    'group' => 'fa-folder-open-o',
    'image' => 'fa-image',
    'sketch' => 'fa-pencil-square-o',
    'audio' => 'fa-volume-up',
    'video' => 'fa-film',
    'counter' => 'fa-plus'
  }

  def form_item_icon(type)
    # Use font awesome icon if defined, else use custom icon from assets dir.
    if cls = FORM_ITEM_ICON_CLASSES[type]
      content_tag(:i, "", class: "fa #{cls} type-icon")
    else
      image_tag("form_items/#{type}.png", class: "type-icon")
    end
  end
end
