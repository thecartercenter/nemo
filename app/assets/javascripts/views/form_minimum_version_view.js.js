class ELMO.Views.FormMinimumVersionView extends ELMO.Views.ApplicationView
  el: 'form.form_form'

  events:
    'regenerable-field:updated .form_current_version_name': 'handleFormVersionIncremented'

  handleFormVersionIncremented: (event, responseData) ->
    val = @$('.form_minimum_version_id select').val()
    @$('.form_minimum_version_id select').html(responseData.minimum_version_options)
    @$('.form_minimum_version_id select').val(val)
