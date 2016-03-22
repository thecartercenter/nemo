class ELMO.Views.MediaUploaderManager extends Backbone.View
  initialize: (options) ->
    @preview_template = options.preview_template
    Dropzone.autoDiscover = false
