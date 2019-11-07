# Controls "return to draft status" button and modal.
class ELMO.Views.ReturnToDraftView extends ELMO.Views.ApplicationView

  el: '.top-action-links'

  events:
    'click .return-to-draft-link': 'show_draft_status_modal'

  show_draft_status_modal: (event) ->
    event.preventDefault()
    event.stopPropagation()
    $('#return-to-draft').modal('show')
