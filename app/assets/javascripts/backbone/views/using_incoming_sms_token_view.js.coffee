class ELMO.Views.UsingIncomingSmsTokenModalView extends Backbone.View

  el: '#using-incoming_sms_token-modal'

  initialize: (options)->
    this.$('.modal-body').html(options.html)

    this.show()

  show: ->
    @$el.modal('show')
