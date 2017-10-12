class ELMO.Views.ConditionFormView extends ELMO.Views.ApplicationView

  # initialize: (options) ->
  #   @condition = options.condition
  #   @questioning_id = options.questioning_id
  #
  # el: '#condition-form-fields'
  #
  # events:
  #   'change #questioning_condition_attributes_ref_qing_id': 'ref_qing_changed'
  #
  # ref_qing_changed: (e) ->
  #   ELMO.app.loading(true)
  #   # Reload the condition form with the selected ref_qing.
  #   url = ELMO.app.url_builder.build('questionings', 'condition-form')
  #   url += '?ref_qing_id=' + $(e.target).val()
  #   url += '&form_id=' + @condition.form_id
  #   url += '&questioning_id=' + @questioning_id if @questioning_id
  #   $(@el).load(url, -> ELMO.app.loading(false))
