/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// The FileUploaderView wraps provides a dropzone file upload interface for uploading one file.
// The zone id is the id of the html element that is the 'dropzone'
// The post path is where the file upload will be posted to.
// The preview template controls what dropzone looks like(typically dropzone_preview.html found in /layouts)
// The paramName is the key to the file in the http request dropzone posts.
// fileUploaded will iterate over keys in successful json response data from the postPath. Where there
// is a hidden input element with a name containing
// the json key, that element's value is set to the json value

ELMO.Views.FileUploaderView = class FileUploaderView extends ELMO.Views.ApplicationView {
  get events() { return { 'click .existing a.delete': 'deleteExisting' }; }

  initialize(options) {
    this.genericThumbPath = options.genericThumbPath;
    this.listener = options.listener;

    this.dropzone = new Dropzone(options.zoneId, {
      url: options.postPath,
      paramName: options.paramName, // The name that will be used to transfer the file
      maxFiles: 1,
      uploadMultiple: false,
      previewTemplate: options.previewTemplate,
      thumbnailWidth: 100,
      thumbnailHeight: 100,
      maxFilesize: options.maxUploadSizeMib, // Note Dropzone docs wrong on param name, look at source code.
    });

    this.dropzone.on('removedfile', () => this.fileRemoved());
    this.dropzone.on('sending', () => this.uploadStarting());
    this.dropzone.on('success', (_, responseData) => this.fileUploaded(responseData));
    this.dropzone.on('error', (file, msg) => this.uploadErrored(file, msg));
    return this.dropzone.on('complete', () => this.uploadFinished());
  }

  deleteExisting(event) {
    event.preventDefault();
    if (confirm($(event.currentTarget).data('confirm-msg'))) {
      this.$('.existing').remove();
      this.$('.dropzone').show();
      return this.clearMetaFields();
    }
  }

  fileUploaded(responseData) {
    const result = [];
    for (const k in responseData) {
      const v = responseData[k];
      result.push(this.$(`input:hidden[name*=${k}]`).val(v));
    }
    return result;
  }

  uploadErrored(file, responseData) {
    this.dropzone.removeFile(file);
    const errors = responseData.errors
      ? responseData.errors.join('<br/>')
      : responseData === 'RECENT_LOGIN_REQUIRED'
        ? I18n.t('errors.file_upload.login_error')
        : I18n.t('errors.file_upload.error');
    return this.$('.dz-error-msg').show().html(errors);
  }

  fileRemoved() {
    this.$('.dz-message').show();
    return this.clearMetaFields();
  }

  uploadStarting() {
    if (this.listener != null) {
      this.listener.uploadStarting();
    }
    if (this.genericThumbPath != null) {
      this.$('img')[0].src = this.genericThumbPath;
    }
    this.$('.dz-message').hide();
    return this.$('.dz-error-msg').hide();
  }

  uploadFinished() {
    if (this.listener != null) {
      return this.listener.uploadFinished();
    }
  }

  clearMetaFields() {
    return this.$('input:hidden').each((index, e) => $(e).val(''));
  }
};
