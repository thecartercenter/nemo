class ELMO.Views.UserListView extends Backbone.View

  el: '.link_set'

  events:
    'click .list-groups': 'show_groups_modal'
    'click .add-to-group': 'add_to_group_modal'
    'click .remove-from-group': 'remove_from_group_modal'

  initialize: (params) ->
    @params = params
    @modal_view = new ELMO.Views.UserGroupsModalView(user_table_view: ELMO.index_table_views.user)

  show_groups_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    @fetch_group_listing(ELMO.app.url_builder.build('user_groups'))

  add_to_group_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    @fetch_group_listing(ELMO.app.url_builder.build('user_groups?add=true'), "add")

  remove_from_group_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    @fetch_group_listing(ELMO.app.url_builder.build('user_groups?remove=true'), "remove")

  fetch_group_listing: (url, mode) ->
    $.ajax
      url: url
      method: "get"
      success: (html) =>
        @modal_view.set_body(html)
        @modal_view.set_mode(mode)
        ELMO.app.loading(false)
        @modal_view.show()
