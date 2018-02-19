class ELMO.Views.UsingIncomingSmsTokenModalView extends ELMO.Views.ApplicationView
  el: '#using-incoming_sms_token-modal'

  initialize: (options) ->
    @$('.modal-body').html(options.html)
    @show()

  show: ->
    @$el.modal('show')
