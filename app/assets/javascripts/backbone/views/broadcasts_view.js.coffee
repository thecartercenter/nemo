class ELMO.Views.BroadcastsView extends Backbone.View
  el: '.broadcast_form'

  initialize: ->
    @medium_changed()
    @$("#broadcast_recipient_ids").select2()

  events:
    'change #broadcast_medium': 'medium_changed'
    'keyup #broadcast_body': 'update_char_limit'

  medium_changed: (e) ->
    selected = @$('#broadcast_medium').val()
    sms_possible = selected != "email_only" && selected != ""

    # Hide/show char limit and subject
    if sms_possible
      @$('#char_limit').show()
      @$('.form_field.broadcast_which_phone').show()
      @$('.form_field.broadcast_subject').hide()
      @$('.form_field.broadcast_balance').show()
      @update_char_limit()
    else
      @$('#char_limit').hide()
      @$('.form_field.broadcast_which_phone').hide()
      @$('.form_field.broadcast_subject').show()
      @$('.form_field.broadcast_balance').hide()

  update_char_limit: ->
    div = @$('#char_limit')
    if div.is(':visible')
      diff = 140 - @$('#broadcast_body').val().length
      msg = I18n.t('broadcast.chars.' + (if diff >= 0 then 'remaining' else 'too_many'))
      div.text("#{Math.abs(diff)} #{msg}")
      div.css('color', if diff >= 0 then 'black' else '#d02000')
