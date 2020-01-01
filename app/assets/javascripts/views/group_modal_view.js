// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (ELMO.Views.GroupModalView = class GroupModalView extends ELMO.Views.FormView {
  static initClass() {
    this.prototype.events = {
      'click .save': 'save',
      keypress: 'keypress',
      'shown.bs.modal': 'modal_shown',
      'click #qing_group_repeatable': 'toggle_item_name',
    };
  }

  initialize(options) {
    this.list_view = options.list_view;
    this.mode = options.mode;

    this.edit_link = options.edit_link;

    if ($('#group-modal').length) {
      $('#group-modal').replaceWith(options.html);
    } else {
      $('body').append(options.html);
    }

    this.setElement($('#group-modal')[0]);
    this.show();
    return ReactRailsUJS.mountComponents('#group-modal');
  }

  serialize() {
    this.form_data = this.$('.qing_group_form').serialize();
    return this.form_data;
  }

  keypress(e) {
    if (e.keyCode === 13) { // Enter
      e.preventDefault();
      return this.save();
    }
  }

  save() {
    ELMO.app.loading(true);

    if (this.mode === 'new') {
      this.new_group();
    } else if (this.mode === 'edit') {
      this.edit_group();
    }

    return this.hide();
  }

  show() {
    return this.$el.modal('show');
  }

  modal_shown() {
    this.$('input[type=text]')[0].focus();
    return this.toggle_item_name();
  }

  hide() {
    return this.$el.modal('hide');
  }

  new_group() {
    this.serialize();

    return $.ajax({
      url: ELMO.app.url_builder.build('qing-groups'),
      method: 'post',
      data: this.form_data,
      success: (data) => {
        this.list_view.add_new_group(data);
        return ELMO.app.loading(false);
      },
    });
  }

  edit_group() {
    this.serialize();

    return $.ajax({
      url: this.edit_link,
      method: 'put',
      data: this.form_data,
      success: (data) => {
        this.list_view.update_group_on_edit(data);
        return ELMO.app.loading(false);
      },
    });
  }

  toggle_item_name() {
    return this.showField('group_item_name_', this.$('#qing_group_repeatable')[0].checked, { prefix: true });
  }
});
Cls.initClass();
