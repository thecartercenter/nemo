class ELMO.Views.UserListView extends Backbone.View

  el: '.link_set'

  events:
    'click .list-groups': 'show_groups_modal'

  initialize: (params) ->
    @params = params

  show_groups_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    $.ajax
      url: ELMO.app.url_builder.build('user_groups')
      method: "get"
      success: (html) =>
        modal_view = new ELMO.Views.UserGroupsModalView({html: html})
        ELMO.app.loading(false)
        modal_view.show()
