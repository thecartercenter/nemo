class ELMO.Views.MediaUploaderView extends Backbone.View
  initialize: (options) ->
    @zone_id = options.zone_id
    @post_path = options.post_path

    Dropzone.options[@zone_id] = {
      url: @post_path
      paramName: "upload" # The name that will be used to transfer the file
      maxFiles: 1
    }




