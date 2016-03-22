class ELMO.Views.MediaUploaderView extends Backbone.View
  initialize: (options) ->
    @zone_id = options.zone_id
    @post_path = options.post_path
    @delete_path = options.delete_path
    @id_field = @$('input')

    @$('.dropzone').dropzone({
      url: @post_path
      paramName: "upload" # The name that will be used to transfer the file
      maxFiles: 1
      uploadMultiple: false
      previewTemplate: ELMO.media_uploader_manager.preview_template
    })

  events:
    'click .existing a.delete': 'delete_existing'
    'success .dropzone': 'file_uploaded'
    'removedfile .dropzone': 'file_removed'

  delete_existing: (event) ->
    event.preventDefault()
    if confirm($(event.currentTarget).data('confirm-msg'))
      $.ajax
        url: @delete_path
        method: "DELETE"
      @$('.existing').remove()
      @$('.dropzone').show()
      @id_field.val('')

  file_uploaded: ->
    @id_field.val(response_data.id)

  file_removed: ->
    @id_field.val('')



