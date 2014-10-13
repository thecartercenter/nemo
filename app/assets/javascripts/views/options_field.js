// ELMO.Views.OptionsField
//
// View model for the options area of the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionsField = klass = function(params) { var self = this;
    self.params = params;
    self.children = params.children;

    // create the draggable list to hold the options
    self.list = new ELMO.Views.DraggableList({
      items: params.children || [],
      item_class: ELMO.Models.OptionNode,
      wrapper: params.wrapper,
      modal: params.modal,
      options_levels_read_only: params.options_levels_read_only,
      multi_level: true,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link,
      parent_change_allowed: self.parent_change_allowed,
      modal_titles: {
        // we only need the edit title for this field
        edit: I18n.t('option_set.edit_option')
      }
    });
  };

  klass.prototype.add = function(option_attribs) { var self = this;
    self.list.add_item({id: null, 'removable?': true, option: option_attribs});
  };

  // Don't allow options that are not removable to change parents.
  klass.prototype.parent_change_allowed = function (item) {
    return item['removable?'];
  }

})(ELMO.Views);
