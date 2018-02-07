class ELMO.Views.GroupModalView extends ELMO.Views.FormView

  events:
    'click .save': 'save'
    'keypress': 'keypress'
    'shown.bs.modal': 'modal_shown'
    'click #qing_group_repeatable': 'toggle_item_name'

  initialize: (options) ->
    @list_view = options.list_view
    @mode = options.mode

    @edit_link = options.edit_link

    if $('#group-modal').length
      $('#group-modal').replaceWith(options.html)
    else
      $('body').append(options.html)

    this.setElement($('#group-modal')[0])
    this.show()

  serialize: ->
    this.form_data = @$('.qing_group_form').serialize()
    return this.form_data

  keypress: (e) ->
    if e.keyCode == 13 # Enter
      e.preventDefault()
      this.save()

  save: ->
    ELMO.app.loading(true)

    if @mode == 'new'
      this.new_group()
    else if @mode == 'edit'
      this.edit_group()

    this.hide()

  show: ->
    @$el.modal('show')

  modal_shown: ->
    @$('input[type=text]')[0].focus()
    @toggle_item_name()

  hide: ->
    @$el.modal('hide')

  new_group: ->
    this.serialize()

    $.ajax({
      url: ELMO.app.url_builder.build('qing-groups'),
      method: "post"
      data: this.form_data,
      success: (data) =>
        @list_view.add_new_group(data)
        ELMO.app.loading(false)
    })

  edit_group: ->
    this.serialize()

    $.ajax({
      url: @edit_link,
      method: "put",
      data: this.form_data,
      success: (data) =>
        @list_view.update_group_on_edit(data)
        ELMO.app.loading(false)
    })

  toggle_item_name: ->
    @showField("group_item_name_", @$("#qing_group_repeatable")[0].checked, prefix: true)
