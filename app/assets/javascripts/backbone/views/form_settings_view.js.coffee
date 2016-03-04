class ELMO.Views.FormSettingsView extends Backbone.View
  el: 'form.form_form'

  events:
    'click .more-settings' : 'show_setting_fields'

  initialize: ->
    this.show_fields_with_errors();

  show_setting_fields: (event) ->
    $(event.target).hide();
    $('.setting_fields').show();

  show_fields_with_errors: ->
    $('.field_with_errors:hidden').closest('.setting_fields').show();
