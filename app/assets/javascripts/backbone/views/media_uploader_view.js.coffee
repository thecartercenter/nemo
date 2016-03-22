class ELMO.Views.MediaUploaderView extends Backbone.View
  initialize: (options) ->
    @zone_id = options.zone_id
    @post_path = options.post_path
    @delete_path = options.delete_path
    @id_field = @$('input')
    @manager = ELMO.media_uploader_manager

    @dropzone = new Dropzone(@zone_id, {
      url: @post_path
      paramName: "upload" # The name that will be used to transfer the file
      maxFiles: 1
      uploadMultiple: false
      previewTemplate: @manager.preview_template
    })

    @dropzone.on 'success', (_, response_data) => @file_uploaded(response_data)
    @dropzone.on 'removedfile', => @file_removed()
    @dropzone.on 'sending', => @upload_starting()
    @dropzone.on 'complete', => @upload_finished()

  events:
    'click .existing a.delete': 'delete_existing'

  delete_existing: (event) ->
    event.preventDefault()
    if confirm($(event.currentTarget).data('confirm-msg'))
      $.ajax
        url: @delete_path
        method: "DELETE"
      @$('.existing').remove()
      @$('.dropzone').show()
      @id_field.val('')

  file_uploaded: (response_data) ->
    @id_field.val(response_data.id)

  file_removed: ->
    @id_field.val('')

  upload_starting: ->
    @manager.upload_starting()

  upload_finished: ->
    @manager.upload_finished()

