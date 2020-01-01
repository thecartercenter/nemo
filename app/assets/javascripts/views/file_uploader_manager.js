/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (ELMO.Views.FileUploaderManager = class FileUploaderManager extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.events = { submit: 'formSubmitted' };
  }

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
});
Cls.initClass();
