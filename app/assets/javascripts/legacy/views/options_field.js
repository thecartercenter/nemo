// ELMO.Views.OptionsField
//
// View model for the options area of the option sets form.
(function (ns, klass) {
  // constructor
  ns.OptionsField = klass = function (params) {
    const self = this;
    self.params = params;
    self.children = params.children;

    // create the draggable list to hold the options
    self.list = new ELMO.Views.DraggableList({
      items: params.children || [],
      item_class: ELMO.Models.OptionNode,
      wrapper: params.wrapper,
      modal: params.modal,
      options_levels_read_only: params.options_levels_read_only,
      multilevel: true,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link,
      parent_change_allowed: self.parent_change_allowed,
      modal_titles: {
        new: I18n.t('option_set.new_option'),
        edit: I18n.t('option_set.edit_option'),
      },
    });
  };

  klass.prototype.add = function () {
    const self = this;
    self.list.new_item();
  };

  // Don't allow options that are not removable to change parents.
  // This is because the way parent change is implemented on the backend is via deleting and re-creating
  // the OptionNode under a new parent, which won't be allowed if the OptionNode has data.
  klass.prototype.parent_change_allowed = function (item) {
    return item.removable;
  };
}(ELMO.Views));
