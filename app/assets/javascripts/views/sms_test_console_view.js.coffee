class ELMO.Views.SmsTestConsoleView extends ELMO.Views.ApplicationView

  el: 'form#new_sms_test'

  events:
    'submit': 'submit'

  submit: (e) ->
    e.preventDefault()

    if @$('input#sms_test_from').val().trim() == ''
      msg = I18n.t('activerecord.errors.messages.blank')
      @$('.sms_test_from .control').prepend('<div class="form-errors">' + msg + '</div>')
      return

    ELMO.app.loading(true)
    @$('.sms_test_result').hide()
    @$('.form-errors').remove()

    $.ajax
      type: 'POST'
      url: @$el.attr('action')
      data: @$el.serialize()
      success: (data) => @$('.sms_test_result div').html(data)
      error: => @$('.sms_test_result div').html('<em>' + I18n.t('sms_console.submit_error') + '</em>')
      complete: =>
        ELMO.app.loading(false)
        @$('.sms_test_result').show()
