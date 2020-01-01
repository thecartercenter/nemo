class ELMO.Views.UserListView extends ELMO.Views.ApplicationView

  el: '#index_table'

  events:
    'click .list-groups': 'show_groups_modal'
    'click .add-to-group': 'add_to_group_modal'
    'click .remove-from-group': 'remove_from_group_modal'

  initialize: (params) ->
    @params = params
    @user_table_view = ELMO.batch_actions_views.user
    @modal_view = new ELMO.Views.UserGroupsModalView(user_table_view: @user_table_view)
    @alert = this.$el.find("div.alert")

  show_groups_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)
    @fetch_group_listing(ELMO.app.url_builder.build('user_groups'))

  add_to_group_modal: (event) ->
    event.preventDefault()
    if @selected_users().length > 0
      ELMO.app.loading(true)
      @fetch_group_listing(ELMO.app.url_builder.build('user_groups?add=true'), "add")
    else
      @alert.html(I18n.t("layout.no_selection")).addClass('alert-danger').show()
      @alert.delay(2500).fadeOut('slow', @user_table_view.reset_alert.bind(this))

  remove_from_group_modal: (event) ->
    event.preventDefault()
    if @selected_users().length > 0
      ELMO.app.loading(true)
      @fetch_group_listing(ELMO.app.url_builder.build('user_groups?remove=true'), "remove")
    else
      @alert.html(I18n.t("layout.no_selection")).addClass('alert-danger').show()
      @alert.delay(2500).fadeOut('slow', @user_table_view.reset_alert.bind(this))

  selected_users: (event) ->
    user_checkboxes = @user_table_view.get_selected_items()
    user_ids = ($(cb).data("userId") for cb in user_checkboxes)

  fetch_group_listing: (url, mode) ->
    $.ajax
      url: url
      method: "get"
      success: (html) =>
        @modal_view.set_body(html)
        @modal_view.set_mode(mode)
        ELMO.app.loading(false)
        @modal_view.show()
