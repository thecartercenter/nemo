# Controls "return to draft status" button and modal.
class ELMO.Views.ReturnToDraftView extends ELMO.Views.ApplicationView

  el: '#action-links-and-modal'

  initialize: (params) ->
    @keyword = params.keyword
    @$('#override').val('') # Ensure box is empty in case cached.

  events:
    'click .return-to-draft-link': 'showDraftStatusModal'
    'shown.bs.modal': 'handleModalShown'
    'keyup #override': 'handleKeyup'

  showDraftStatusModal: (event) ->
    event.preventDefault()
    event.stopPropagation()
    @$('#return-to-draft').modal('show')

  handleModalShown: (event) ->
    @$('#override').focus()

  handleKeyup: (event) ->
    @$('.btn-primary').toggle(@$(event.target).val() == @keyword)
