class ELMO.Views.PrintFormView extends ELMO.Views.ApplicationView

  initialize: ->
    # For some reason this doesn't work if you put it in the events hash.
    $('#form-print-format-tips').on('hidden.bs.modal', => this.load_printable_form())

  el: '#content'

  events:
    'click a.print-link': 'print_form'

  print_form: (e) ->
    e.preventDefault()

    this.id = $(e.currentTarget).data('form-id')

    if this.should_show_format_tips()
      this.show_format_tips_modal()
    else
      this.load_printable_form()

  load_printable_form: ->
    ELMO.app.loading(true)

    # Delete any previous print content stuff in case print multiple times.
    $('.print-content').remove()

    # Load specially formatted show page into div.
    $.ajax
      url: ELMO.app.url_builder.build('forms', this.id)
      method: 'get'
      headers:
        accept: 'text/html' # Without this, we get 404 due to route constraints.
      data: {print: 1}
      success: (data) =>
        $('<div>').addClass('print-content').html(data).appendTo(this.el)
        ELMO.app.loading(false)
        this.do_print()

  should_show_format_tips: ->
    # Show if not already shown today.
    window.localStorage.getItem('form_print_format_tips_shown') != this.datestamp()

  show_format_tips_modal: ->
    window.localStorage.setItem('form_print_format_tips_shown', this.datestamp())
    $('#form-print-format-tips').modal('show')

  # Shows the print dialog, or just a dummy modal if in test mode.
  do_print: ->
    window.print()

  datestamp: ->
    d = new Date()
    d.getFullYear() + '-' + d.getMonth() + '-' + d.getDate()
