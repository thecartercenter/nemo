# Initializes the popovers for hints on a form. Should be called for any form with hints.
class ELMO.Views.FormHintView extends ELMO.Views.ApplicationView
  initialize: (params) ->
    @$('a.hint').popover(html: true)
