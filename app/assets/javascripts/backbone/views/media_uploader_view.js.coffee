class ELMO.Views.MediaUploaderView extends Backbone.View
  initialize: (options) ->
    @zone_id = options.zone_id
    @post_path = options.post_path
    @delete_path = options.delete_path

    Dropzone.options[@zone_id] = {
      url: @post_path
      paramName: "upload" # The name that will be used to transfer the file
      maxFiles: 1
      uploadMultiple: false
      previewTemplate: ELMO.Response.dropzone_preview_template

      success: (_, response_data) =>
        @$('input').val(response_data.id)
    }

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





