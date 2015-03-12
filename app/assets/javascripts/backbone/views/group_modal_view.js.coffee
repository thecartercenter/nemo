class ELMO.Views.GroupModalView extends Backbone.View

  el: 'body'

  events:
    'click .save': 'save'

  initialize: (options) ->
    @list_view = options.list_view
    @mode = options.mode

    # TODO: Remove once edit_group link uses url_builder
    @edit_link = options.edit_link

    if $('.group-modal').length
      $('.group-modal').replaceWith(options.html)
    else
      $('body').append(options.html)

    this.show()

  serialize: ->
    @form_data = $('.qing_group_form').serialize()

  save: ->
    this.serialize()
    ELMO.app.loading(true)

    if @mode == 'new'
      this.new_group()
    else if @mode == 'edit'
      this.edit_group()

  show: ->
    $('.group-modal').modal('show')

  hide: ->
    $('.group-modal').modal('hide')

  new_group: ->
    $.ajax({
      url: ELMO.app.url_builder.build('qing-groups', this.id),
      method: "post"
      data: @form_data,
      success: (data) =>
        @list_view.add_new_group(data)
        this.hide()
        ELMO.app.loading(false)
    })

  edit_group: ->
    $.ajax({
      url: @edit_link, # TODO: Replace URL with url_builder link
      method: "put",
      data: @form_data,
      success: (data) =>
        @list_view.update_group_on_edit(data)
        this.hide()
        ELMO.app.loading(false)
    })
