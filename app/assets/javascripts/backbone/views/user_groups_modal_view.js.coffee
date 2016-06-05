class ELMO.Views.UserGroupsModalView extends Backbone.View
  el: '#user-groups-modal'

  events:
    "ajax:success": "process_response"

  initialize: (params) ->
    @params = params
    @set_body(params.html)

  set_body: (html) ->
    @$('.modal-body').html(html)

  show: ->
    $(@el).modal('show')

  process_response: (e, data, status, xhr) ->
    event_target = e.target
    if @$(event_target).hasClass("action_link_destroy")
      target_row = $(event_target).closest("tr")
      @$(target_row).remove()
      @$(".header.link_set").html(data.page_entries_info)
