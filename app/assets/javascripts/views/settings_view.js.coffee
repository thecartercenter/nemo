class ELMO.Views.SettingsView extends ELMO.Views.ApplicationView

  el: 'form.setting_form'

  events:
    'click #external_sql .control a': 'select_external_sql'
    'click .adapter-settings a': 'show_change_credential_fields'
    'click .using-incoming_sms_token': 'show_using_incoming_sms_token_modal'
    'click .using-universal_sms_token': 'show_using_universal_sms_token_modal'
    'click .credential-fields input[type=checkbox]:checked': 'clear_sms_fields'

  initialize: (options) ->
    this.need_credentials = options.need_credentials || {}
    this.show_credential_fields_with_errors()

  select_external_sql: (event) ->
    @$("#external_sql .control pre").selectText()
    return false

  show_change_credential_fields: (event) ->
    @$(event.target).hide()
    @$(event.target).closest('.adapter-settings').find(".credential-fields").show()
    return false

  show_using_universal_sms_token_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)

    $.ajax
      url: ELMO.app.url_builder.build('settings', 'using_incoming_sms_token_message?missionless=1')
      success: (data) ->
        new ELMO.Views.UsingIncomingSmsTokenModalView({html: data.message.replace(/\n/g, "<br/>")})
      complete: ->
        ELMO.app.loading(false)

  show_using_incoming_sms_token_modal: (event) ->
    event.preventDefault()
    ELMO.app.loading(true)

    $.ajax
      url: ELMO.app.url_builder.build('settings', 'using_incoming_sms_token_message')
      success: (data) ->
        new ELMO.Views.UsingIncomingSmsTokenModalView({html: data.message.replace(/\n/g, "<br/>")})
      complete: ->
        ELMO.app.loading(false)

  show_credential_fields_with_errors: ->
    adapters = @$('.form-field.has-errors:hidden').closest('.adapter-settings')
    @$(adapters).find('.credential-fields').show()
    @$(adapters).find('a.show-credential-fields').hide()

  clear_sms_fields: (event) ->
    inputs = @$(event.target).closest('.adapter-settings').find('input[type=text]')
    @$(inputs).val('')
