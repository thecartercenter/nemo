// ELMO.Views.OptionsField
//
// View model for the options area of the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionsField = klass = function(params) { var self = this;
    self.params = params;
    self.optionings = params.optionings;

    self.list = new ELMO.Views.DraggableList({
      // items in list are Options, which implement NamedItem
      items: params.optionings,
      wrapper: params.wrapper,
      modal: params.modal,
      form_mode: params.form_mode,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove_options,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link
    });
  };

  // given a hash of option attribs, creates Optioning and Option objects and adds to OptioningCollection and DraggableList
  klass.prototype.add = function(option_attribs) { var self = this;
    // don't add if it's a duplicate
    if (self.optionings.has_with_name(option_attribs.name)) return false;

    var optioning = new ELMO.Models.Optioning({
      id: null,
      'removable?': true,
      option: new ELMO.Models.Option(option_attribs)
    });

    // add to data model (returns new optioning)
    self.optionings.add(optioning);

    // add Option to list
    self.list.add_item(optioning);
  };

})(ELMO.Views);
