/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Controls draggable list behavior for form items list.
ELMO.Views.FormItemsDraggableListView = class FormItemsDraggableListView extends ELMO.Views.ApplicationView {
  get el() { return '.form-items-list'; }

  initialize(params) {
    this.parent_view = params.parent_view;

    return $('.item-list').nestedSortable({
      handle: 'div',
      items: 'li',
      toleranceElement: '> div',
      forcePlaceholderSize: true,
      placeholder: 'placeholder',
      isAllowed: (placeholder, parent, item) => {
        return this.drop_target_is_allowed(placeholder, parent, item);
      },
      update: (event, ui) => {
        return this.drop_happened(event, ui);
      },
    });
  }

  drop_target_is_allowed(placeholder, parent, item) {
    let reason = null;

    // Must be undefined parent or group type.
    if (parent && !parent.hasClass('form-item-group')) {
      reason = 'parent_must_be_group';
    } else if (!this.check_condition_order(placeholder, item)) {
      reason = 'invalid_condition';
    }

    // Show the reason if applicable.
    const html = reason ? `<div>${I18n.t(`form.invalid_drop_location.${reason}`)}</div>` : '';
    placeholder.html(html);

    return !reason;
  }

  // Called at the end of a drag. Saves new position.
  drop_happened(event, ui) {
    this.update_condition_refs();
    this.parent_view.update_group_action_icons();
    return this.parent_view.update_item_position(ui.item.data('id'), this.get_parent_id_and_rank(ui.item));
  }

  // Gets the parent_id (or null if top-level) and rank of the given li.
  get_parent_id_and_rank(li) {
    const parent = li.parent().closest('li.form-item');
    return {
      parent_id: parent.length ? parent.data('id') : null,
      rank: li.prevAll('li.form-item').length + 1,
    };
  }

  // Gets the fully qualified rank, as an array of integers, of the given item/li.
  get_full_rank(li) {
    const path = li.parents('li.form-item, li.placeholder').andSelf();
    const ranks = path.map(function () { return $(this).prevAll('li.form-item, li.placeholder').length + 1; });
    return ranks.get();
  }

  // Updates any condition cross-references after a drop or delete.
  update_condition_refs() {
    return this.$('.condition').each((i, cond) => {
      cond = $(cond);
      const refd = this.$(`li.form-item[data-id=${cond.data('ref-id')}]`);
      if (refd.length) {
        return cond.find('span').html(this.get_full_rank(refd).join('.'));
      }
      return cond.remove();
    });
  }

  // Checks if the given position (indicated by placeholder) for the given item, or any of its children,
  // would invalidate any conditions.
  // Returns false if invalid.
  check_condition_order(placeholder, item) {
    // If item or any children refer to questions, the placeholder must be after all the referred questions.
    for (const c of Array.from(item.find('.refd-qing'))) {
      const refd = this.$(`li.form-item[data-id=${$(c).data('ref-id')}]`);
      if (this.compare_ranks(placeholder, refd) !== 1) { return false; }
    }

    // If item, or any children, are referred to by one or more questions,
    // the placeholder must be before all the referring questions.
    const child_ids = item.find('.form-item').andSelf().map(function () { return $(this).data('id'); });
    for (const id of Array.from(child_ids.get())) {
      for (const refd_qing of Array.from(this.$(`.refd-qing[data-ref-id=${id}]`))) { // Loop over all matching refd_qings
        const referrer = $(refd_qing.closest('li.form-item'));
        if (this.compare_ranks(placeholder, referrer) !== -1) { return false; }
      }
    }

    return true;
  }

  // Compares ranks of two items, returning 1 if a > b, 0 if a == b, -1 if a < b
  compare_ranks(a, b) {
    const ar = this.get_full_rank(a);
    const br = this.get_full_rank(b);
    for (let i = 0; i < ar.length; i++) {
      const _ = ar[i];
      if (ar[i] > br[i]) {
        return 1;
      } else if (ar[i] < br[i]) {
        return -1;
      }
    }

    // If we get to this point, all ranks so far have been equal.
    // If both a and b are same length, we can return 0. Else,
    // the greater rank is the longer one.
    if (ar.length === br.length) { return 0; } else if (ar.length > br.length) { return 1; } return -1;
  }
};
