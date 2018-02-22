class ELMO.Views.MediaUploaderManager extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @preview_template = options.preview_template
    Dropzone.autoDiscover = false
    @uploads_in_progress = 0

  events:
    'submit': 'form_submitted'

  form_submitted: (event) ->
    if @uploads_in_progress != 0
      event.preventDefault()

  upload_starting: ->
    @uploads_in_progress++
    @update_buttons()

  upload_finished: ->
    @uploads_in_progress--
    @update_buttons()

  update_buttons: ->
    can_submit = @uploads_in_progress == 0
    @$(".submit-buttons .btn-primary").css('display', if can_submit then 'inline-block' else 'none')
    @$("#upload-progress-notice").css('display', if can_submit then 'none' else 'inline-block')
