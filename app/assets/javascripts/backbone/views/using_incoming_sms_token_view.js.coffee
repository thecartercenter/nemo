class ELMO.Views.UsingIncomingSmsTokenModalView extends Backbone.View

  el: '#using-incoming_sms_token-modal'

  initialize: ->
    this.show()

  show: ->
    @$el.modal('show')
