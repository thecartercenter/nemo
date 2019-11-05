# Controls "return to draft status" button and modal.
class ELMO.Views.ReturnToDraftStatusActionLinkView extends ELMO.Views.ApplicationView

  el: '.top-action-links'

  events:
    'click .return-to-draft-status-link': 'show_draft_status_modal'

  show_draft_status_modal: (event) ->
    event.preventDefault()
    event.stopPropagation()
    $('#return-to-draft-status').modal('show')
