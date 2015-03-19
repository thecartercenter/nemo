class ELMO.Views.FormItemsView extends Backbone.View

  el: '.form-items'

  events:
    'click .add-group': 'show_new_group_modal'
    'click .form-item-group .edit': 'show_edit_group_modal'
    'click .form-item-group .delete': 'delete_group'

  initialize: (params) ->
    this.nested_list()
    this.params = params

  show_new_group_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)

    $.ajax
      url: ELMO.app.url_builder.build('qing-groups', 'new'),
      method: "get",
      data: {form_id: this.params.form_id},
      success: (html) =>
        new ELMO.Views.GroupModalView({html: html, list_view: this, mode: 'new'})
        ELMO.app.loading(false)


  show_edit_group_modal: (event) ->
    event.preventDefault()
    $link = $(event.currentTarget)
    @form_item_being_edited = $link.closest('.form-item')

    url = $link.attr("href")
    edit_link = url.replace('/edit', '')

    ELMO.app.loading(true)

    $.ajax
      url: url,
      method: "get",
      success: (html) =>
        new ELMO.Views.GroupModalView
          html: html,
          list_view: this,
          mode: 'edit',
          edit_link: edit_link
        ELMO.app.loading(false)

  add_new_group: (data) ->
    $('.form-items-list').append(data)

  update_group_on_edit: (data) ->
    @form_item_being_edited.replaceWith(data)

  delete_group: (event) ->
    event.preventDefault()
    $link = $(event.currentTarget)
    this.remove_group(event) if confirm $link.data('message')

  remove_group: (event) ->
    $link = $(event.currentTarget)
    url = $link.attr("href")
    $form_item = $link.closest('.form-item')

    ELMO.app.loading(true)

    $.ajax
      url: url,
      method: "delete",
      success: =>
        $form_item.remove()
        ELMO.app.loading(false)

  # TODO: Ensure only groups can hold children, rather than all items in item list
  nested_list: ->
    $('.item-list').nestedSortable
      placeholder: 'placeholder'
      isAllowed: (item, parent) =>
        this.drop_target_is_allowed(item, parent)
      update: (event, ui) =>
        this.drop_happened(event, ui)

  drop_target_is_allowed: (item, parent) ->
    # Must be null parent or group type.
    allowed = parent == null || parent.hasClass('form-item-group')

    # If not allowed, show the placeholder border as red.
    $('.form-items .placeholder').css('border-color', if allowed then '#aaa' else 'red')

    # Return
    allowed

  # Called at the end of a drag.
  drop_happened: (event, ui) ->
    $.ajax
      url: ELMO.app.url_builder.build('form-items', ui.item.data('id'))
      method: 'put'
      data: this.get_parent_id_and_rank(ui.item)

  # Gets the parent_id (or null if top-level) and rank of the given li.
  get_parent_id_and_rank: (li) ->
    parent = li.parent().closest('li.form-item')
    {
      parent_id: if parent.length then parent.data('id') else null,
      rank: li.prevAll('li.form-item').length + 1
    }
