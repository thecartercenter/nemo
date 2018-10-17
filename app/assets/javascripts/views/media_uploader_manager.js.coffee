class ELMO.Views.MediaUploaderManager extends ELMO.Views.ApplicationView
  initialize: (options) ->
    Dropzone.autoDiscover = false
    @uploadsInProgress = 0

  events:
    'submit': 'formSubmitted'

  isUploading: ->
    @uploadsInProgress > 0

  formSubmitted: (event) ->
    if @uploadsInProgress != 0
      event.preventDefault()

  uploadStarting: ->
    @uploadsInProgress++
    @updateButtons()

  uploadFinished: ->
    @uploadsInProgress--
    @updateButtons()

  updateButtons: ->
    canSubmit = @uploadsInProgress == 0
    @$(".submit-buttons .btn-primary").css('display', if canSubmit then 'inline-block' else 'none')
    @$("#upload-progress-notice").css('display', if canSubmit then 'none' else 'inline-block')
