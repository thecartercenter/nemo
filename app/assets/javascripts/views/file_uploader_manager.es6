/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.FileUploaderManager = class FileUploaderManager extends ELMO.Views.ApplicationView {
  get events() { return { submit: 'formSubmitted' }; }

  initialize(options) {
    Dropzone.autoDiscover = false;
    return this.uploadsInProgress = 0;
  }

  isUploading() {
    return this.uploadsInProgress > 0;
  }

  formSubmitted(event) {
    if (this.uploadsInProgress !== 0) {
      return event.preventDefault();
    }
  }

  uploadStarting() {
    this.uploadsInProgress++;
    return this.updateButtons();
  }

  uploadFinished() {
    this.uploadsInProgress--;
    return this.updateButtons();
  }

  updateButtons() {
    const canSubmit = this.uploadsInProgress === 0;
    this.$('.submit-buttons .btn-primary').css('display', canSubmit ? 'inline-block' : 'none');
    return this.$('#upload-progress-notice').css('display', canSubmit ? 'none' : 'inline-block');
  }
};
