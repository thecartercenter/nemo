// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (ELMO.Views.UserListView = class UserListView extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.el = '#index_table';

    this.prototype.events = {
      'click .list-groups': 'show_groups_modal',
      'click .add-to-group': 'add_to_group_modal',
      'click .remove-from-group': 'remove_from_group_modal',
    };
  }

  initialize(params) {
    this.params = params;
    this.user_table_view = ELMO.batch_actions_views.user;
    this.modal_view = new ELMO.Views.UserGroupsModalView({ user_table_view: this.user_table_view });
    return this.alert = this.$el.find('div.alert');
  }

  show_groups_modal(event) {
    event.preventDefault();
    ELMO.app.loading(true);
    return this.fetch_group_listing(ELMO.app.url_builder.build('user_groups'));
  }

  add_to_group_modal(event) {
    event.preventDefault();
    if (this.selected_users().length > 0) {
      ELMO.app.loading(true);
      return this.fetch_group_listing(ELMO.app.url_builder.build('user_groups?add=true'), 'add');
    }
    this.alert.html(I18n.t('layout.no_selection')).addClass('alert-danger').show();
    return this.alert.delay(2500).fadeOut('slow', this.user_table_view.reset_alert.bind(this));
  }

  remove_from_group_modal(event) {
    event.preventDefault();
    if (this.selected_users().length > 0) {
      ELMO.app.loading(true);
      return this.fetch_group_listing(ELMO.app.url_builder.build('user_groups?remove=true'), 'remove');
    }
    this.alert.html(I18n.t('layout.no_selection')).addClass('alert-danger').show();
    return this.alert.delay(2500).fadeOut('slow', this.user_table_view.reset_alert.bind(this));
  }

  selected_users(event) {
    let user_ids;
    const user_checkboxes = this.user_table_view.get_selected_items();
    return user_ids = (Array.from(user_checkboxes).map((cb) => $(cb).data('userId')));
  }

  fetch_group_listing(url, mode) {
    return $.ajax({
      url,
      method: 'get',
      success: (html) => {
        this.modal_view.set_body(html);
        this.modal_view.set_mode(mode);
        ELMO.app.loading(false);
        return this.modal_view.show();
      },
    });
  }
});
Cls.initClass();
