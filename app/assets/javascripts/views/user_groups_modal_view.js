/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.UserGroupsModalView = class UserGroupsModalView extends ELMO.Views.ApplicationView {
  get el() { return '#user-groups-modal'; }

  get events() {
    return {
      'ajax:success .action-link-edit': 'process_edit',
      'ajax:success .action-link-destroy': 'process_destroy',
      'click a.update-name': 'update_name',
      'click .add_to_group': 'add_users_to_group',
      'click .remove_from_group': 'remove_users_from_group',
    };
  }

  initialize(params) {
    this.params = params;
    this.user_table_view = params.user_table_view;
    this.mode = params.mode;
    return this.set_body(params.html);
  }

  set_body(html) {
    return this.$el.html(html);
  }

  set_mode(mode) {
    return this.mode = mode;
  }

  show() {
    return this.$el.modal('show');
  }

  create_group(e) {
    e.preventDefault();
    const group_name = prompt(I18n.t('user_group.create_prompt'));
    const mode = ((this.mode === 'add') || (this.mode === 'remove')) ? `user_groups?${this.mode}=true` : 'user_groups';
    ELMO.app.loading(true);
    return $.ajax({
      url: ELMO.app.url_builder.build(mode),
      method: 'post',
      data: { name: group_name },
      success: (html) => {
        this.set_body(html);
        return ELMO.app.loading(false);
      },
      error: (data) => {
        this.$el.modal('hide');
        return location.reload();
      },
    });
  }

  add_users_to_group(e) {
    e.preventDefault();
    const user_checkboxes = this.user_table_view.get_selected_items();
    const user_ids = (Array.from(user_checkboxes).map((cb) => $(cb).data('userId')));
    const selected_group = this.$el.find('#user-group').val();
    if (user_ids.length > 0) {
      return $.ajax({
        url: ELMO.app.url_builder.build(`user_groups/${selected_group}/add_users`),
        method: 'post',
        data: { user_ids },
        success: (data) => {
          this.$el.modal('hide');
          return location.reload();
        },
        error: (data) => {
          this.$el.modal('hide');
          return location.reload();
        },
      });
    }
  }

  remove_users_from_group(e) {
    e.preventDefault();
    const user_checkboxes = this.user_table_view.get_selected_items();
    const user_ids = (Array.from(user_checkboxes).map((cb) => $(cb).data('userId')));
    const selected_group = this.$el.find('#user-group').val();
    if (user_ids.length > 0) {
      return $.ajax({
        url: ELMO.app.url_builder.build(`user_groups/${selected_group}/remove_users`),
        method: 'post',
        data: { user_ids },
        success: (data) => {
          this.$el.modal('hide');
          return location.reload();
        },
        error: (data) => {
          this.$el.modal('hide');
          return location.reload();
        },
      });
    }
  }


  update_name(e) {
    e.preventDefault();
    const target_url = $(e.currentTarget).attr('href');
    const target_value = $(e.currentTarget).closest('tr').find('input').val();
    return $.ajax({
      url: target_url,
      method: 'patch',
      data: { name: target_value },
      success: (data) => {
        return this.$(e.currentTarget).closest('tr').find('.name_col').html(`<div>${data.name}</div>`);
      },
      error: (data) => {
        this.$el.modal('hide');
        return location.reload();
      },
    });
  }


  process_edit(e, data, status, xhr) {
    const target_field = $(e.target).closest('tr').find('.name_col');
    return this.$(target_field).html(data);
  }

  process_destroy(e, data) {
    const target_row = $(e.target).closest('tr');
    this.$(target_row).remove();
    return this.$('.index-links').html(data.page_entries_info);
  }
};
