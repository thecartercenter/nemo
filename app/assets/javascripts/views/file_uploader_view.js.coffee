# The FileUploaderView wraps provides a dropzone file upload interface for uploading one file.
# The zone id is the id of the html element that is the 'dropzone'
# The post path is where the file upload will be posted to.
# The preview template controls what dropzone looks like(typically dropzone_preview.html found in /layouts)
# The paramName is the key to the file in the http request dropzone posts.

class ELMO.Views.FileUploaderView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @zoneId = options.zoneId
    @postPath = options.postPath
    @genericThumbPath = options.genericThumbPath
    @metaField = @$('input')
    @metaFieldResponseAttr = options.metaFieldResponseAttr
    @previewTemplate = options.previewTemplate
    @paramName = options.paramName
    @listener = options.listener


    @dropzone = new Dropzone(@zoneId, {
      url: @postPath
      paramName: @paramName # The name that will be used to transfer the file
      maxFiles: 1
      uploadMultiple: false
      previewTemplate: @previewTemplate,
      thumbnailWidth: 100,
      thumbnailHeight: 100
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
      @metaField.val('')

  fileUploaded: (responseData) ->
    @metaField.val(responseData[@metaFieldResponseAttr])

  uploadErrored: (file, responseData) ->
    @dropzone.removeFile(file)
    errors = if responseData.errors
      responseData.errors.join("<br/>")
    else
      I18n.t('errors.file_upload')
    @$('.error-msg').show().html(errors)

  fileRemoved: ->
    @$('.dz-message').show()
    @metaField.val('')

  uploadStarting: ->
    if @listener?
      @listener.uploadStarting()
    @$('img')[0].src = @genericThumbPath
    @$('.dz-message').hide()
    @$('.error-msg').hide()

  uploadFinished: ->
    if @listener?
      @listener.uploadFinished()
