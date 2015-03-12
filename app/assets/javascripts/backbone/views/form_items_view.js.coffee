class ELMO.Views.FormItemsView extends Backbone.View

  el: '.form-items'

  events:
    'click .add-group': 'show_new_group_modal'
    'click .form-group .edit': 'show_edit_group_modal'
    'click .form-group .delete': 'delete_group'

  initialize: (params) ->
    this.nested_list()
    this.params = params

  show_new_group_modal: (link) ->
    link.preventDefault()
    ELMO.app.loading(true)

    $.ajax({
      url: ELMO.app.url_builder.build('qing-groups', 'new'),
      method: "get",
      data: {form_id: this.params.form_id},
      success: (html) =>
        new ELMO.Views.GroupModalView({html: html, list_view: this, mode: 'new'})
        ELMO.app.loading(false)
    })

  show_edit_group_modal: (link) ->
    link.preventDefault()
    $link = $(link.currentTarget)
    @form_item_being_edited = $link.closest('.form-item')

    # TODO: replace with url_builder links, if possible
    url = $link.attr("href")
    @edit_link = url.replace('/edit', '')

    ELMO.app.loading(true)

    $.ajax({
      url: url,
      method: "get",
      success: (html) =>
        new ELMO.Views.GroupModalView({
          html: html,
          list_view: this,
          mode: 'edit',
          edit_link: @edit_link
        })
        ELMO.app.loading(false)
    })

  add_new_group: (data) ->
    $('<li>').html(data).appendTo('.form-items-list')

  update_group_on_edit: (data) ->
    @form_item_being_edited.replaceWith(data)

  delete_group: (link) ->
    link.preventDefault()
    this.remove_group(link) if confirm "Are you sure you want to delete this group?"

  remove_group: (link) ->
    $link = $(link.currentTarget)
    url = $link.attr("href")
    $form_item = $link.closest('.form-item')

    ELMO.app.loading(true)

    $.ajax({
      url: url,
      method: "delete",
      success: =>
        $form_item.remove()
        ELMO.app.loading(false)
    })

    # TODO: make sure console error "no element found" does not show on removal
      # Appears to be trying to open the modal for some reason.
        # Started GET "/en/m/panglossia/qing-groups/161"
        # AbstractController::ActionNotFound (The action 'show' could not be found for QingGroupsController):

  nested_list: ->
    $('.item-list').nestedSortable({

      # TODO: Ensure groups are only form item that can have children
        # Below is the default configuration

      handle: 'div',
      items: 'li',
      toleranceElement: '> div'

      isAllowed: (li, parent) =>
        return true
    })
