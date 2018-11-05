# The FileUploaderView wraps provides a dropzone file upload interface for uploading one file.
# The zone id is the id of the html element that is the 'dropzone'
# The post path is where the file upload will be posted to.
# The preview template controls what dropzone looks like(typically dropzone_preview.html found in /layouts)
# The paramName is the key to the file in the http request dropzone posts.
# fileUploaded will iterate over keys in successful json response data from the postPath. Where there
# is a hidden input element with a name containing
# the json key, that element's value is set to the json value

class ELMO.Views.FileUploaderView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @zoneId = options.zoneId
    @postPath = options.postPath
    @genericThumbPath = options.genericThumbPath
    @previewTemplate = options.previewTemplate
    @paramName = options.paramName
    @acceptedFileFormats = options.acceptedFileFormats
    @listener = options.listener


    @dropzone = new Dropzone(@zoneId, {
      url: @postPath,
      paramName: @paramName, # The name that will be used to transfer the file
      maxFiles: 1,
      uploadMultiple: false,
      previewTemplate: @previewTemplate,
      thumbnailWidth: 100,
      thumbnailHeight: 100,
      acceptedFiles: @acceptedFileFormats,
      maxFilesize: 50 #MB, fits a maximum row xlsx file. Note dz docs wrong, look at source.
    })

    @dropzone.on 'removedfile', => @fileRemoved()
    @dropzone.on 'sending', => @uploadStarting()
    @dropzone.on 'success', (_, responseData) => @fileUploaded(responseData)
    @dropzone.on 'error', (file, msg) => @uploadErrored(file, msg)
    @dropzone.on 'complete', => @uploadFinished()

  events:
    'click .existing a.delete': 'deleteExisting'

  deleteExisting: (event) ->
    event.preventDefault()
    if confirm($(event.currentTarget).data('confirm-msg'))
      @$('.existing').remove()
      @$('.dropzone').show()
      @clearMetaFields()

  fileUploaded: (responseData) ->
    for k, v of responseData
      @$("input:hidden[name*=#{k}]").val(v)

  uploadErrored: (file, responseData) ->
    @dropzone.removeFile(file)
    errors = if responseData.errors
      responseData.errors.join("<br/>")
    else
      I18n.t('errors.file_upload.error')
    @$('.dz-error-msg').show().html(errors)

  fileRemoved: ->
    @$('.dz-message').show()
    @clearMetaFields()

  uploadStarting: ->
    if @listener?
      @listener.uploadStarting()
    if @genericThumbPath?
      @$('img')[0].src = @genericThumbPath
    else
      @$('img').hide()
      @$('.dz-details').css('margin', '0px')
    @$('.dz-message').hide()
    @$('.dz-error-msg').hide()

  uploadFinished: ->
    if @listener?
      @listener.uploadFinished()

  clearMetaFields: ->
    @$('input:hidden').each (index, e) =>
      $(e).val('')
