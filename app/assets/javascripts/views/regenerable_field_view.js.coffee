class ELMO.Views.RegenerableFieldView extends ELMO.Views.ApplicationView

  events:
    'click .regenerate': 'regenerateField'

  regenerateField: (event) ->
    event.preventDefault()

    target = $(event.currentTarget)
    handler = target.data('handler')
    confirmMsg = target.data('confirm-msg')

    container = target.closest('.regenerable-field')
    displayEl = container.find('span[data-value]')
    inlineLoadInd = container.find('div.inline-load-ind img')
    successIndicator = container.find('.success')
    errorIndicator = container.find('.failure')

    # If confirm text is provided and there is a current value,
    # show a confirmation dialog
    if (confirmMsg && displayEl.data('value') && !window.confirm(confirmMsg))
      return false

    # Disable the button and ensure that only the loading indicator is shown
    target.attr('disabled', 'disabled')
    successIndicator.hide()
    errorIndicator.hide()
    inlineLoadInd.show()

    $.ajax
      method: 'patch'
      url: handler
      success: (data) =>
        # Trigger an event that other views can subscribe to, with the response data as the first param.
        @$el.trigger('regenerable-field:updated', [data])
        if (displayEl.length > 0)
          $(displayEl[0]).data(value: data.value)
          $(displayEl[0]).text(data.value)
        inlineLoadInd.hide()
        successIndicator.show()
      error: ->
        inlineLoadInd.hide()
        errorIndicator.show()
      complete: ->
        target.removeAttr('disabled')
