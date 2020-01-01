class ELMO.Views.UserLoginInstructionsView extends ELMO.Views.ApplicationView
  events:
    "click .masked a.toggle-mask": "unmask"
    "click .unmasked a.toggle-mask": "mask"

  unmask: (event) ->
    event.preventDefault()
    container = $(event.target).closest('.mask-container')
    container.find('.masked').addClass('d-none')
    container.find('.unmasked').removeClass('d-none')

  mask: (event) ->
    event.preventDefault()
    container = $(event.target).closest('.mask-container')
    container.find('.unmasked').addClass('d-none')
    container.find('.masked').removeClass('d-none')
