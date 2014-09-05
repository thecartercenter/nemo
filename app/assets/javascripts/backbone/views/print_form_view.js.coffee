class ELMO.Views.PrintFormView extends Backbone.View

  el: '#content'

  events:
    'click a.print-link': 'show_dialog'

  show_dialog: (e) ->
    e.preventDefault()
    ELMO.app.loading(true)
    form_id = $(e.currentTarget).data('form-id')

    # Delete any previous print content stuff in case print multiple times.
    $('.print-content').remove()

    # Need to save this alias b/c weird things happen with ELMO in success method.
    ELMO_alias = ELMO

    # Load specially formatted show page into div.
    $.ajax({
      url: ELMO.app.url_builder.build('forms', form_id),
      method: "get",
      data: {print: 1},
      success: (data) =>
        $('<div>').addClass('print-content').html(data).appendTo(this.el)
        ELMO_alias.app.loading(false)
        window.print()
    })
