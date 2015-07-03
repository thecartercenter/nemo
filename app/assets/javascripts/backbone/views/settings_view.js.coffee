class ELMO.Views.SettingsView extends Backbone.View

  el: 'form.setting_form'

  events:
    'click #external_sql .control a': 'select_external_sql'
    'click .adapter_settings a': 'show_change_credential_fields'
    'click .using-incoming_sms_token': 'show_using_incoming_sms_token_modal'

  initialize: (options) ->
    this.need_credentials = options.need_credentials || {}

  select_external_sql: (event) ->
    $("form.setting_form #external_sql .control pre").selectText()
    return false

  show_change_credential_fields: (event) ->
    $(event.target).hide()
    $(event.target).closest('.adapter_settings').find(".credential_fields").show()
    return false

  show_using_incoming_sms_token_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)

    $.ajax
      url: ELMO.app.url_builder.build('settings', 'using_incoming_sms_token_message')
      success: (data) ->
        new ELMO.Views.UsingIncomingSmsTokenModalView({ html: data.message.replace(/\n/g, "<br/>") })
      complete: ->
        ELMO.app.loading(false)
