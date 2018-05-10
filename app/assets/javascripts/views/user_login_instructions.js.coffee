class ELMO.Views.UserLoginInstructionsView extends ELMO.Views.ApplicationView
  events:
    "click .masked a.toggle_mask": "unmask_password"
    "click .unmasked a.toggle_mask": "mask_password"

  unmask_password: (event) ->
    event.preventDefault()
    this.$('.masked').addClass('hide')
    this.$('.unmasked').removeClass('hide')

  mask_password: (event) ->
    event.preventDefault()
    this.$('.unmasked').addClass('hide')
    this.$('.masked').removeClass('hide')
