/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.UserProfileFormView = class UserProfileFormView extends ELMO.Views.ApplicationView {
  get el() { return 'form.user_form'; }

  get events() {
    return {
      'change select#user_gender': 'toggle_custom_gender_visibility',
      'change select#user_reset_password_method': 'toggle_password_fields',
    };
  }

  initialize(params) {
    this.params = params || {};
    this.init_user_group_select();
    this.toggle_custom_gender_visibility();
    return this.toggle_password_fields();
  }

  init_user_group_select() {
    const option_builder = new ELMO.Utils.Select2OptionBuilder();
    return this.$('#user_user_group_ids').select2({
      tags: true,
      templateResult: this.format_suggestions,
      ajax: option_builder.ajax(this.params.user_group_options_url, 'possible_groups', 'name'),
    });
  }

  format_suggestions(item) {
    if (item.id === item.text) {
      return $(`<li><i class="fa fa-fw fa-plus-circle"></i>${item.text
      } <span class="details create_new">[${I18n.t('user_group.new_group')}]</span>` + '</li>');
    }
    return item.text;
  }

  toggle_custom_gender_visibility(event) {
    const select_value = this.$('select#user_gender').val();
    if (select_value === 'specify') {
      return this.$('div.user_gender_custom').show();
    }
    this.$('input#user_gender_custom').val('');
    return this.$('div.user_gender_custom').hide();
  }

  toggle_password_fields(event) {
    const select_value = this.$('select#user_reset_password_method').val();
    return this.$('.password-fields').toggleClass('d-none', (select_value !== 'enter') && (select_value !== 'enter_and_show'));
  }
};
