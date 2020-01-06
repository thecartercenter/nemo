/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.ResponseFormView = class ResponseFormView extends ELMO.Views.ApplicationView {
  get events() { return { 'click .qtype-location .widget a': 'showLocationPicker' }; }

  initialize(params) {
    // Select2's for user and reviewer
    this.$('#response_user_id').select2({ ajax: (new ELMO.Utils.Select2OptionBuilder()).ajax(params.submitter_url, 'possible_users', 'name') });
    this.$('#response_reviewer_id').select2({ ajax: (new ELMO.Utils.Select2OptionBuilder()).ajax(params.reviewer_url, 'possible_users', 'name') });

    return this.locationPicker = new ELMO.LocationPicker(this.$('#location-picker-modal'));
  }

  showLocationPicker(e) {
    e.preventDefault();
    const field = this.$(e.target).closest('.widget').find('input[type=text]');
    return this.locationPicker.show(field);
  }
};
