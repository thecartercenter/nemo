class ELMO.Views.UsingIncomingSmsTokenModalView extends ELMO.Views.ApplicationView
  el: '#using-incoming-sms-token-modal'

  initialize: (options) ->
    @$('.modal-body').html(options.html)
    @show()

  show: ->
    @$el.modal('show')
