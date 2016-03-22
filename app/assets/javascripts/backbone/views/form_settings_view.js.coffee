class ELMO.Views.FormSettingsView extends Backbone.View
  el: 'form.form_form'

  events:
    'click .more-settings' : 'show_setting_fields'
    'click .less-settings' : 'hide_setting_fields'

  initialize: ->
    this.show_fields_with_errors();

  show_setting_fields: (event) ->
    event.preventDefault();
    $('.more-settings').hide();
    $('.less-settings').show();
    $('.setting_fields').show();

  hide_setting_fields: (event) ->
    event.preventDefault();
    $('.more-settings').show();
    $('.less-settings').hide();
    $('.setting_fields').hide();

  show_fields_with_errors: ->
    $('.field_with_errors:hidden').closest('.setting_fields').show();
