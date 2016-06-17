class ELMO.Views.UserGroupsModalView extends Backbone.View
  el: '#user-groups-modal'

  events:
    "ajax:success .action_link_edit": "process_edit"
    "ajax:success .action_link_destroy": "process_destroy"
    "click a.action_link_update": "update_name"
    "click button.new": "create_group"
    "click .add-to-group": "add_users_to_group"

  initialize: (params) ->
    @params = params
    @user_table_view = params.user_table_view
    @add_mode = params.add_mode
    @set_body(params.html)

  set_body: (html) ->
    @$('.modal-body').html(html)

  show: ->
    $(@el).modal('show')

  create_group: (e) ->
    e.preventDefault();
    group_name = prompt(I18n.t('user_group.create_prompt'))
    url_mode = if @add_mode then 'user_groups?add=true' else 'user_groups'
    ELMO.app.loading(true)
    $.ajax
      url: ELMO.app.url_builder.build(url_mode)
      method: "post"
      data: { name: group_name }
      success: (html) =>
        @$(".modal-body").html(html)
        ELMO.app.loading(false)


  add_users_to_group: (e) ->
    e.preventDefault()
    user_checkboxes = @user_table_view.get_selected_items()
    user_ids = ($(cb).data('userId') for cb in user_checkboxes)
    if user_ids.length > 0
      $.ajax
        url: $(e.currentTarget).attr("href")
        method: "post"
        data: { user_ids: user_ids }
        success: (data) =>
          @$el.modal('hide')
          location.reload()

  update_name: (e) ->
    e.preventDefault();
    target_url = $(e.currentTarget).attr("href")
    target_value = $(e.currentTarget).closest("tr").find("input").val()
    $.ajax
      url: target_url
      method: "patch"
      data: { name: target_value }
      success: (data) =>
        @$(e.currentTarget).closest("tr").find(".name_col").html("<div>" + data.name + "</div>")


  process_edit: (e, data, status, xhr) ->
    target_field = $(e.target).closest("tr").find(".name_col")
    @$(target_field).html(data)

  process_destroy: (e, data) ->
    target_row = $(e.target).closest("tr")
    @$(target_row).remove()
    @$(".header.link_set").html(data.page_entries_info)
