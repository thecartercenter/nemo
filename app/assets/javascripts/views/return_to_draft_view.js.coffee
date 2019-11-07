# Controls "return to draft status" button and modal.
class ELMO.Views.ReturnToDraftView extends ELMO.Views.ApplicationView

  el: '#action-links-and-modal'

  initialize: (params) ->
    @keyword = params.keyword
    @$('#override').val('') # Ensure box is empty in case cached.
    @accepted = false

  events:
    'click .return-to-draft-link': 'handleLinkClicked'
    'shown.bs.modal #return-to-draft-modal': 'handleModalShown'
    'click #return-to-draft-modal .btn-primary': 'handleAcceptClicked'
    'keyup #override': 'handleKeyup'

  handleLinkClicked: (event) ->
    # If accept button was clicked, we just let the link do it's thing.
    return if @accepted

    event.preventDefault()
    event.stopPropagation()
    @$('#return-to-draft-modal').modal('show')

  handleModalShown: (event) ->
    @$('#override').focus()

  handleKeyup: (event) ->
    @$('.btn-primary').toggle(@$(event.target).val() == @keyword)

  handleAcceptClicked: (event) ->
    @accepted = true
    # Trigger another click on the link so we can use the data-method machinery to make the PUT request.
    @$('.return-to-draft-link').trigger('click')
