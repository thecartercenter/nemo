/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
ELMO.Views.RepeatGroupFormView = class RepeatGroupFormView extends ELMO.Views.ApplicationView {
  get events() {
    return {
      'click .add-instance': 'add_instance',
      'click .remove-instance': 'remove_instance',
    };
  }

  initialize(options) {
    this.tmpl = options.tmpl;
    return this.next_inst_num = parseInt(this.$el.data('inst-count')) + 1;
  }

  add_instance(event) {
    event.preventDefault();
    const qing_group = $(event.target).closest('.qing-group');
    qing_group.find('.qing-group-instances').append(this.tmpl.replace(/__INST_NUM__/g, this.next_inst_num));
    return this.next_inst_num++;
  }

  remove_instance(event) {
    event.preventDefault();
    const instance = $(event.target.closest('.qing-group-instance'));
    instance.hide();
    return instance.find('[id$=_destroy]').val('1');
  }
};
