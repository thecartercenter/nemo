# The FileUploaderView wraps provides a dropzone file upload interface for uploading one file.
# The zone id is the id of the html element that is the 'dropzone'
# The post path is where the file upload will be posted to.
# The preview template controls what dropzone looks like and it typically dropzone_preview.html (found in /layouts)
# The paramName is the key to the file in the http request dropzone posts.

class ELMO.Views.FileUploaderView extends ELMO.Views.ApplicationView
  initialize: (options) ->
    @zone_id = options.zone_id
    @post_path = options.post_path
    @delete_path = options.delete_path
    @generic_thumb_path = options.generic_thumb_path
    @id_field = @$('input')
    @preview_template = options.preview_template
    @paramName = options.param_name
    @listener = options.listener

    @dropzone = new Dropzone(@zone_id, {
      url: @post_path
      paramName: @paramName # The name that will be used to transfer the file
      maxFiles: 1
      uploadMultiple: false
      previewTemplate: @preview_template,
      thumbnailWidth: 100,
      thumbnailHeight: 100
    })

    @dropzone.on 'removedfile', => @file_removed()
    @dropzone.on 'sending', => @upload_starting()
    @dropzone.on 'success', (_, response_data) => @file_uploaded(response_data)
    @dropzone.on 'error', (file, msg) => @upload_errored(file, msg)
    @dropzone.on 'complete', => @upload_finished()

  events:
    'click .existing a.delete': 'delete_existing'

  delete_existing: (event) ->
    event.preventDefault()
    if confirm($(event.currentTarget).data('confirm-msg'))
      @$('.existing').remove()
      @$('.dropzone').show()
      @id_field.val('')

  file_uploaded: (response_data) ->
    @id_field.val(response_data.id)

  upload_errored: (file, response_data) ->
    @dropzone.removeFile(file)
    errors = if response_data.errors
      response_data.errors.join("<br/>")
    else
      I18n.t('errors.file_upload')
    @$('.error-msg').show().html(errors)

  file_removed: ->
    @$('.dz-message').show()
    @id_field.val('')

  upload_starting: ->
    if @listener
      @listener.upload_starting()
    @$('img')[0].src = @generic_thumb_path
    @$('.dz-message').hide()
    @$('.error-msg').hide()

  upload_finished: ->
    if @listener
      @listener.upload_finished()
