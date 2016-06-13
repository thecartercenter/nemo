class ELMO.Views.UserGroupsModalView extends Backbone.View
  el: '#user-groups-modal'

  events:
    "ajax:success .action_link_edit": "process_edit"
    "ajax:success .action_link_destroy": "process_destroy"
    "click a.action_link_update": "update_name"
    "click button.new": "create_group"

  initialize: (params) ->
    @params = params
    @set_body(params.html)

  set_body: (html) ->
    @$('.modal-body').html(html)

  show: ->
    $(@el).modal('show')

  create_group: (e) ->
    e.preventDefault();
    group_name = prompt(I18n.t('user_group.create_prompt'))
    # @$(".modal-body").html("")
    ELMO.app.loading(true)
    $.ajax
      url: ELMO.app.url_builder.build('user_groups')
      method: "post"
      data: { name: group_name }
      success: (html) =>
        @$(".modal-body").html(html)
        ELMO.app.loading(false)


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
