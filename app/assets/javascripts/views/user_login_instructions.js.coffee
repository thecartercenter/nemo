class ELMO.Views.UserLoginInstructionsView extends ELMO.Views.ApplicationView
  events:
    "click .masked a.toggle-mask": "unmask"
    "click .unmasked a.toggle-mask": "mask"

  unmask: (event) ->
    event.preventDefault()
    container = $(event.target).closest('.mask-container')
    container.find('.masked').addClass('hide')
    container.find('.unmasked').removeClass('hide')

  mask: (event) ->
    event.preventDefault()
    container = $(event.target).closest('.mask-container')
    container.find('.unmasked').addClass('hide')
    container.find('.masked').removeClass('hide')
