class ELMO.Views.UserListView extends Backbone.View

  el: '.link_set'

  events:
    'click .list-groups': 'show_groups_modal'
    'click .add-to-group': 'add_to_group_modal'

  initialize: (params) ->
    @params = params

  show_groups_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    @fetch_group_listing(ELMO.app.url_builder.build('user_groups'))

  add_to_group_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    @fetch_group_listing(ELMO.app.url_builder.build('user_groups?add=true'), true)

  fetch_group_listing: (url, add_mode) ->
    $.ajax
      url: url
      method: "get"
      success: (html) =>
        modal_view = new ELMO.Views.UserGroupsModalView({html: html, user_table_view: ELMO.index_table_views.user, add_mode: true})
        ELMO.app.loading(false)
        modal_view.show()
