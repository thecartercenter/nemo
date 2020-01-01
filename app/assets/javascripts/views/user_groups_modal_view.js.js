class ELMO.Views.UserGroupsModalView extends ELMO.Views.ApplicationView
  el: '#user-groups-modal'

  events:
    "ajax:success .action-link-edit": "process_edit"
    "ajax:success .action-link-destroy": "process_destroy"
    "click a.update-name": "update_name"
    "click .add_to_group": "add_users_to_group"
    "click .remove_from_group": "remove_users_from_group"

  initialize: (params) ->
    @params = params
    @user_table_view = params.user_table_view
    @mode = params.mode
    @set_body(params.html)

  set_body: (html) ->
    $(@el).html(html)

  set_mode: (mode) ->
    @mode = mode

  show: ->
    $(@el).modal("show")

  create_group: (e) ->
    e.preventDefault()
    group_name = prompt(I18n.t("user_group.create_prompt"))
    mode = if (@mode == "add" || @mode == "remove") then "user_groups?#{@mode}=true" else "user_groups"
    ELMO.app.loading(true)
    $.ajax
      url: ELMO.app.url_builder.build(mode)
      method: "post"
      data: {name: group_name}
      success: (html) =>
        @set_body(html)
        ELMO.app.loading(false)
      error: (data) =>
        @$el.modal("hide")
        location.reload()

  add_users_to_group: (e) ->
    e.preventDefault()
    user_checkboxes = @user_table_view.get_selected_items()
    user_ids = ($(cb).data("userId") for cb in user_checkboxes)
    selected_group = @$el.find("#user-group").val()
    if user_ids.length > 0
      $.ajax
        url: ELMO.app.url_builder.build("user_groups/#{selected_group}/add_users")
        method: "post"
        data: {user_ids: user_ids}
        success: (data) =>
          @$el.modal("hide")
          location.reload()
        error: (data) =>
          @$el.modal("hide")
          location.reload()

  remove_users_from_group: (e) ->
    e.preventDefault()
    user_checkboxes = @user_table_view.get_selected_items()
    user_ids = ($(cb).data("userId") for cb in user_checkboxes)
    selected_group = @$el.find("#user-group").val()
    if user_ids.length > 0
      $.ajax
        url: ELMO.app.url_builder.build("user_groups/#{selected_group}/remove_users")
        method: "post"
        data: {user_ids: user_ids}
        success: (data) =>
          @$el.modal("hide")
          location.reload()
        error: (data) =>
          @$el.modal("hide")
          location.reload()


  update_name: (e) ->
    e.preventDefault()
    target_url = $(e.currentTarget).attr("href")
    target_value = $(e.currentTarget).closest("tr").find("input").val()
    $.ajax
      url: target_url
      method: "patch"
      data: {name: target_value}
      success: (data) =>
        @$(e.currentTarget).closest("tr").find(".name_col").html("<div>" + data.name + "</div>")
      error: (data) =>
        @$el.modal("hide")
        location.reload()


  process_edit: (e, data, status, xhr) ->
    target_field = $(e.target).closest("tr").find(".name_col")
    @$(target_field).html(data)

  process_destroy: (e, data) ->
    target_row = $(e.target).closest("tr")
    @$(target_row).remove()
    @$(".header.link_set").html(data.page_entries_info)
