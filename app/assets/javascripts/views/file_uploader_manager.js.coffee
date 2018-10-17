class ELMO.Views.FileUploaderManager extends ELMO.Views.ApplicationView
  initialize: (options) ->
    Dropzone.autoDiscover = false

  events:
    'submit': 'formSubmitted'

  uploadStarting: ->
    console.log("upload starting")

  uploadFinished: ->
    console.log("upload finished")
