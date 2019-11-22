class ELMO.Views.RegenerableFieldView extends ELMO.Views.ApplicationView

  events:
    'click .regenerate': 'regenerate_field'

  regenerate_field: (event) ->
    event.preventDefault()

    target = $(event.currentTarget)
    handler = target.data('handler')
    confirm = target.data('confirm')

    container = target.closest('.regenerable-field')
    displayEl = container.find('span[data-value]')
    inline_load_ind = container.find('div.inline-load-ind img')
    success_indicator = container.find('.success')
    error_indicator = container.find('.failure')

    # If confirm text is provided and there is a current value,
    # show a confirmation dialog
    if (confirm && displayEl.data('value') && !window.confirm(confirm))
      return false

    # Disable the button and ensure that only the loading indicator is shown
    target.attr('disabled', 'disabled')
    success_indicator.hide()
    error_indicator.hide()
    inline_load_ind.show()

    $.ajax
      method: 'patch'
      url: handler
      success: (data) ->
        if (displayEl.length > 0)
          $(displayEl[0]).data(value: data.value)
          $(displayEl[0]).text(data.value)
          target.text(I18n.t('common.regenerate'))
        inline_load_ind.hide()
        success_indicator.show()
      error: ->
        inline_load_ind.hide()
        error_indicator.show()
      complete: ->
        target.removeAttr('disabled')
