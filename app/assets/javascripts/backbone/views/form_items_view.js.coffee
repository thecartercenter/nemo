class ELMO.Views.FormItemsView extends Backbone.View

  el: '.form-items'

  events:
    'click .add-group': 'show_new_group_modal'
    'click .form-item-group > .inner .edit': 'show_edit_group_modal'
    'click .form-item-group > .inner .delete': 'delete_item'
    'click .form-item-question > .inner .delete': 'delete_item'

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
        this.update_condition_refs()
        ELMO.app.loading(false)

  nested_list: ->
    $('.item-list').nestedSortable
      handle: 'div',
      items: 'li',
      toleranceElement: '> div',
      forcePlaceholderSize: true,
      placeholder: 'placeholder',
      isAllowed: (placeholder, parent, item) =>
        this.drop_target_is_allowed(placeholder, parent, item)
      update: (event, ui) =>
        this.drop_happened(event, ui)

  drop_target_is_allowed: (placeholder, parent, item) ->
    # Must be undefined parent or group type.
    allowed = !parent || parent.hasClass('form-item-group')

    # If not allowed, show the placeholder border as red.
    $('.form-items .placeholder').css('border-color', if allowed then '#aaa' else 'red')

    # Return
    allowed

  # Called at the end of a drag. Saves new position.
  drop_happened: (event, ui) ->
    this.update_condition_refs()

    this.show_saving_message(true)
    $.ajax
      url: ELMO.app.url_builder.build('form-items', ui.item.data('id'))
      method: 'put'
      data: this.get_parent_id_and_rank(ui.item)
      success: =>
        this.show_saving_message(false)

  # Gets the parent_id (or null if top-level) and rank of the given li.
  get_parent_id_and_rank: (li) ->
    parent = li.parent().closest('li.form-item')
    {
      parent_id: if parent.length then parent.data('id') else null,
      rank: li.prevAll('li.form-item').length + 1
    }

  # Gets the fully qualified rank of the given item/li.
  get_full_rank: (li) ->
    path = li.parents('li.form-item').andSelf()
    ranks = path.map -> $(this).prevAll('li.form-item').length + 1
    ranks.get().join('.')

  # Updates any condition cross-references after a drop or delete.
  update_condition_refs: ->
    @$(".condition").each (i, cond) =>
      cond = $(cond)
      refd = @$("li.form-item[data-id=#{cond.data('ref-id')}]")
      if refd.length
        cond.find('span').html(this.get_full_rank(refd))
      else
        cond.remove()

  show_saving_message: (show) ->
    @$('#saving-message')[if show then 'show' else 'hide']()
