/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Controls add/edit/delete operations for form items list.
ELMO.Views.FormItemsView = class FormItemsView extends ELMO.Views.ApplicationView {
  get el() { return '.form-items'; }

  get events() {
    return {
      'click .add-group': 'show_new_group_modal',
      'click .form-item-group > .inner': 'show_edit_group_modal',
      'click .form-item-group > .inner .action-link-edit': 'show_edit_group_modal',
      'click .form-item-group > .inner .action-link-destroy': 'delete_item',
      'click .form-item-question': 'go_to_question',
      'click .form-item-question > .inner .action-link-destroy': 'delete_item',
    };
  }

  initialize(params) {
    if (params.can_reorder) { this.draggable = new ELMO.Views.FormItemsDraggableListView({ parent_view: this }); }
    this.params = params;
    return this.update_group_action_icons();
  }

  show_new_group_modal(event) {
    event.preventDefault();
    ELMO.app.loading(true);

    return $.ajax({
      url: ELMO.app.url_builder.build('qing-groups', 'new'),
      method: 'get',
      data: { form_id: this.params.form_id },
      success: (html) => {
        new ELMO.Views.GroupModalView({ html, list_view: this, mode: 'new' });
        return ELMO.app.loading(false);
      },
    });
  }

  show_edit_group_modal(event) {
    event.preventDefault(); // Don't follow link (it's just '#')
    event.stopPropagation(); // Don't bubble up or we can get a double-call of this handler if pencil clicked.

    const $link = $(event.currentTarget);
    this.form_item_being_edited = $link.closest('.form-item');
    const url = $link.attr('href');
    const edit_link = url.replace('/edit', '');

    ELMO.app.loading(true);

    return $.ajax({
      url,
      method: 'get',
      success: (html) => {
        new ELMO.Views.GroupModalView({ html, list_view: this, mode: 'edit', edit_link });
        return ELMO.app.loading(false);
      },
    });
  }

  add_new_group(data) {
    this.$('.form-items-list').append(data);
    return this.$('.no-questions-notice').hide();
  }

  update_group_on_edit(data) {
    return this.form_item_being_edited.find('> .inner').replaceWith(data);
  }

  delete_item(event) {
    event.preventDefault(); // Don't follow link (it's just '#')
    event.stopPropagation(); // Don't bubble up or go_to_question/show_edit_group_modal may get called.

    const $link = $(event.currentTarget);
    if (!confirm($link.data('message'))) { return; }

    ELMO.app.loading(true);
    const $form_item = $link.closest('li.form-item');

    const route = $form_item.hasClass('form-item-group') ? 'qing-groups' : 'questionings';

    return $.ajax({
      url: ELMO.app.url_builder.build(route, $form_item.data('id')),
      method: 'delete',
      success: () => {
        $form_item.remove();
        this.draggable.update_condition_refs();
        this.update_group_action_icons();
        return ELMO.app.loading(false);
      },
    });
  }

  update_item_position(id, parent_and_rank) {
    this.show_saving_message(true);
    return $.ajax({
      url: ELMO.app.url_builder.build('form-items', id),
      method: 'put',
      data: parent_and_rank,
      success: () => {
        return this.show_saving_message(false);
      },
    });
  }

  // Checks all groups and hides/shows delete icons when appropriate.
  update_group_action_icons() {
    const result = [];
    for (const group of Array.from(this.$('.form-item-group'))) {
      const link = $(group).find('> .inner .action-link.action-link-destroy');
      result.push(link[$(group).find('.form-item').length > 0 ? 'hide' : 'show']());
    }
    return result;
  }

  show_saving_message(show) {
    return this.$('#saving-message')[show ? 'show' : 'hide']();
  }

  go_to_question(e) {
    if (!(this.$(e.target).parents('a').length > 0)) { return window.location.href = this.$(e.currentTarget).data('href'); }
  }
};
