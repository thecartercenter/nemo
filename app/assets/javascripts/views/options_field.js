// ELMO.Views.OptionsField
//
// View model for the options area of the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionsField = klass = function(params) { var self = this;
    self.params = params;
    self.root_node = params.root_node;

    // create the draggable list to hold the options
    self.list = new ELMO.Views.DraggableList({
      items: params.root_node.children,
      item_class: ELMO.Models.OptionNode,
      wrapper: params.wrapper,
      modal: params.modal,
      form_mode: params.form_mode,
      multi_level: true,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link,
      modal_titles: {
        // we only need the edit title for this field
        edit: I18n.t('option_set.edit_option')
      }
    });
  };

  klass.prototype.add = function(option_attribs) { var self = this;
    self.list.add_item({id: null, 'removable?': true, option: option_attribs});
  };


})(ELMO.Views);
