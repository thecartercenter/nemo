# Controls add/edit/delete operations for form items list.
class ELMO.Views.FormItemsView extends ELMO.Views.ApplicationView

  el: '.form-items'

  events:
    'click .add-group': 'show_new_group_modal'
    'click .form-item-group > .inner .edit': 'show_edit_group_modal'
    'click .form-item-group > .inner .delete': 'delete_item'
    'click .form-item-question > .inner .delete': 'delete_item'
    'click .form-item-question': 'go_to_question'

  initialize: (params) ->
    this.draggable = new ELMO.Views.FormItemsDraggableListView({parent_view: this}) if params.can_reorder
    this.params = params
    this.update_action_icons()

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
    @$('.form-items-list').append(data)
    @$('.no-questions-notice').hide()

  update_group_on_edit: (data) ->
    @form_item_being_edited.find('> .inner').replaceWith(data)

  delete_item: (event) ->
    event.preventDefault()

    $link = $(event.currentTarget)
    return unless confirm $link.data('message')

    ELMO.app.loading(true)
    $form_item = $link.closest('li.form-item')

    route = if $form_item.hasClass('form-item-group') then 'qing-groups' else 'questionings'

    $.ajax
      url: ELMO.app.url_builder.build(route, $form_item.data('id'))
      method: "delete"
      success: =>
        $form_item.remove()
        this.draggable.update_condition_refs()
        ELMO.app.loading(false)

  update_item_position: (id, parent_and_rank) ->
    this.show_saving_message(true)
    $.ajax
      url: ELMO.app.url_builder.build('form-items', id)
      method: 'put'
      data: parent_and_rank
      success: =>
        this.show_saving_message(false)

  # Checks all groups and hides/shows delete icons when appropriate.
  update_action_icons: ->
    for group in @$('.form-item-group')
      link = $(group).find('> .inner .action_link.delete')
      link[if $(group).find('.form-item').length > 0 then 'hide' else 'show']()

  show_saving_message: (show) ->
    @$('#saving-message')[if show then 'show' else 'hide']()

  go_to_question: (e) ->
    window.location.href = @$(e.currentTarget).data('href') unless @$(e.target).parents('a').length > 0
