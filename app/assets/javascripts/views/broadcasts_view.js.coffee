class ELMO.Views.BroadcastsView extends ELMO.Views.FormView
  el: '.broadcast_form'

  initialize: (options) ->
    @medium_changed()
    @recipient_selection_changed()

    @$("#broadcast_recipient_ids").select2
      ajax:
        url: options.recipient_options_url
        dataType: 'json'
        data: (params) -> {q: params.term, page: params.page || 1}
        delay: 250
        cache: true

  events:
    'change #broadcast_medium': 'medium_changed'
    'change #broadcast_recipient_selection': 'recipient_selection_changed'
    'keyup #broadcast_body': 'update_char_limit'

  recipient_selection_changed: (e) ->
    specific = @form_value('broadcast', 'recipient_selection') == 'specific'
    @showField('recipient_ids', specific)

  medium_changed: (e) ->
    selected = @form_value('broadcast', 'medium')
    sms_possible = selected != 'email_only' && selected != ''
    @$('#char_limit').toggle(sms_possible)
    @showField('which_phone', sms_possible)
    @showField('subject', !sms_possible)
    @update_char_limit() if sms_possible

  update_char_limit: ->
    div = @$('#char_limit')
    if div.is(':visible')
      diff = 140 - @$('#broadcast_body').val().length
      msg = I18n.t('broadcast.chars.' + (if diff >= 0 then 'remaining' else 'too_many'))
      div.text("#{Math.abs(diff)} #{msg}")
      div.css('color', if diff >= 0 then 'black' else '#d02000')
