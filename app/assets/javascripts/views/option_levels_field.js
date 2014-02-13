// ELMO.Views.OptionLevelsField
//
// View model for the options area of the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionLevelsField = klass = function(params) { var self = this;
    self.params = params;
    self.option_levels = params.option_levels;

    // create the draggable list to hold the options
    self.list = new ELMO.Views.DraggableList({
      items: params.option_levels,
      wrapper: params.wrapper,
      modal: params.modal,
      form_mode: params.form_mode,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link
    });
  };

  // given a hash of option attribs, creates Optioning and Option objects and adds to OptioningCollection and DraggableList
  klass.prototype.add = function(option_attribs) { var self = this;
  };

  klass.prototype.show = function(yn) { var self = this;
    $('.form_field[data-field-name=option_levels')[yn ? 'show' : 'hide']();
  };

})(ELMO.Views);
