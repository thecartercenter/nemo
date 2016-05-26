class ELMO.Views.UserListView extends Backbone.View

  el: '.link_set'

  events:
    'click .list-groups': 'show_groups_modal'

  initialize: (params) ->
    this.params = params

  show_groups_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    $.ajax
      url: ELMO.app.url_builder.build('user_groups'),
      method: "get",
      data: {},
      success: (html) =>
        new ELMO.Views.UserGroupsModalView({html: html})
        ELMO.app.loading(false)
        $("#user-groups-modal").modal('show')
