class ELMO.Views.ConditionFormView extends Backbone.View

  initialize: (condition) ->
    @condition = condition

  el: '#condition-form-fields'

  events:
    'change #questioning_condition_attributes_ref_qing_id': 'ref_qing_changed'

  ref_qing_changed: (e) ->
    ELMO.app.loading(true)
    # Reload the condition form with the selected ref_qing.
    url = ELMO.app.url_builder.build('questionings', 'condition-form')
    url += '?ref_qing_id=' + $(e.target).val()
    url += '&form_id=' + @condition.form_id
    $(@el).load(url, -> ELMO.app.loading(false))
