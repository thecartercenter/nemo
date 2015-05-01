class ELMO.Views.SettingsView extends Backbone.View

  el: 'form.setting_form'

  events:
    'click #external_sql .control a': 'select_external_sql'
    'click .adapter_settings a': 'show_change_password_fields'

  select_external_sql: (event) ->
    $("form.setting_form #external_sql .control pre").selectText();
    return false;

  show_change_password_fields: (event) ->
    console.log('Changing');
    $(event.target).hide();
    $(event.target).closest('.adapter_settings').find(".password_fields").show();
    return false;
