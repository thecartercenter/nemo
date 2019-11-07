# Controls "return to draft status" button and modal.
class ELMO.Views.ReturnToDraftView extends ELMO.Views.ApplicationView

  el: '#action-links-and-modal'

  initialize: (params) ->
    @keyword = params.keyword

  events:
    'click .return-to-draft-link': 'showDraftStatusModal'
    'keyup #override': 'handleKeyup'

  showDraftStatusModal: (event) ->
    event.preventDefault()
    event.stopPropagation()
    @$('#return-to-draft').modal('show')

  handleKeyup: (event) ->
    console.log(@$(event.target).val(), @keyword)
    @$('.btn-primary').toggle(@$(event.target).val() == @keyword)
