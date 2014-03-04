// ELMO.Views.DraggableList
//
// View model for a draggable, editable list of options/levels/whatever.
(function(ns, klass) {

  // constructor
  ns.DraggableList = klass = function(attribs) { var self = this;
    self.listeners = {};

    // copy attribs
    for (var key in attribs) self[key] = attribs[key];

    self.removed_items = [];

    self.dirty = false;

    // render the items
    self.render_items();

    // hookup setup edit/remove links (deferred)
    self.wrapper.on('click', 'a.action_link_edit', function(){
      self.edit_item($(this).closest('div.inner').data('item'));
      return false;
    });

    self.wrapper.on('click', 'a.action_link_remove', function(){
      self.remove_item($(this).closest('div.inner').data('item'));
      return false;
    });

    // hookup save and cancel buttons on modal
    self.modal.find('button.btn-primary').on('click', function(){ self.save_item(); return false; });
    self.modal.find('button.btn-default').on('click', function(){ self.cancel_edit(); });

    // show/hide save button when translations change
    $('body').on('keyup change', '.edit-named-item div.translation input', function(e){
      // if all translation boxes in this modal are blank, hide the 'save' button
      var show = false;
      $(e.target).closest('.modal').find('div.translation input').each(function(){
        if ($(this).val().trim() != '') {
          show = true;
          return false;
        }
      });
      $(e.target).closest('.modal').find('.btn-primary')[show ? 'show' : 'hide']();
    });
  };

  // renders the html to the view
  klass.prototype.render_items = function() { var self = this;
    // create outer ol tag
    self.ol = $("<ol>");

    // add li tags
    self.items.forEach(function(item, idx){
      $('<li>').html(self.render_item(item)).appendTo(self.ol);
    });

    // append to wrapper div
    self.wrapper.append(self.ol);

    // setup the sortable plugin unless in show mode
    if (self.form_mode != 'show' && self.can_reorder) {
      self.ol.nestedSortable({
        handle: 'div',
        items: 'li',
        toleranceElement: '> div',
        maxLevels: self.multi_level ? 0 : 1,

        // notify model when sorting changes
        change: function(){ self.items.dirty = true; }
      });
    }
  };

  // builds the inner div tag for an item
  klass.prototype.render_item = function(item) { var self = this;

    // make inner tag
    var inner = $('<div>').attr('class', 'inner');

    // wrap the item in an object if not already wrapped
    if (!item.translation)
      item = new self.item_class(item);

    // add sort icon if not in show mode
    if (self.form_mode != 'show' && self.can_reorder)
      inner.append($('<i>').attr('class', 'icon-sort'));

    // add name (add nbsp to make sure div doesn't collapse if name is blank)
    inner.append(item.translation() + '&nbsp;');

    // add edit/remove unless in show mode
    if (self.form_mode != 'show') {
      var links = $('<div>').attr('class', 'links')

      // only show the edit link if the item is editable
      if (item.editable)
        links.append(self.edit_link);

      // don't show the removable link if the item isn't removable
      // or if the global removable permission is false
      if (self.can_remove && item.removable)
        links.append(self.remove_link);

      // add a spacer if empty, else it won't render right
      if (links.is(':empty'))
        links.append('&nbsp;')

      links.appendTo(inner);
    }

    // add locales
    inner.append($('<em>').html(item.locale_str()));

    // associate item with data model bidirectionally
    inner.data('item', item);
    item.div = inner;

    return inner;
  };

  // adds an item to the view
  // item_attribs - the item attributes
  klass.prototype.add_item = function(item_attribs) { var self = this;
    // wrap in object
    var item = new self.item_class(item_attribs);

    // check for duplicates
    if (self.has_duplicate_of(item))
      return false;

    // wrap in li and add to view
    $('<li>').html(self.render_item(item)).appendTo(self.ol);

    self.dirty = true;
    self.trigger('change');
  };

  // shows the 'new' modal
  klass.prototype.new_item = function() { var self = this;
    self.show_modal(new self.item_class(), {mode: 'new'});
  };

  // shows the 'edit' modal
  // item - the model object to be edited
  klass.prototype.edit_item = function(item) { var self = this;
    self.show_modal(item, {mode: 'edit'});
  };

  // shows the new/edit modal
  // item - the model object to be shown
  // options[mode] - whether to show as new or edit
  klass.prototype.show_modal = function(item, options) { var self = this;
    // save the as an instance var as we will need to access it
    // when the modal gets closed
    self.active_item = item;

    // save mode
    self.modal_mode = options.mode;

    // set title
    self.modal.find('.modal-title').text(self.modal_titles[options.mode]);

    // clear the text boxes
    self.modal.find('.translation input').val("");

    // hide the in_use warning
    self.modal.find('div[id$=in_use_name_change_warning]').hide();

    // then populate text boxes
    self.active_item.locales().forEach(function(l){
      self.modal.find('.translation input[id$=name_' + l + ']').val(self.active_item.translation(l));
    });

    // show the modal
    self.modal.modal('show');

    // show the in_use warning if appopriate
    if (self.active_item.in_use) self.modal.find('div[id$=in_use_name_change_warning]').show();
  };

  // removes an item from the view
  // item - the model object to be removed
  klass.prototype.remove_item = function(item) { var self = this;
    // get li element
    var li = item.div.closest('li');

    // notify models of all children
    li.find('div.inner').each(function(){ self.removed_items.push($(this).data('item')); });

    // remove li from view
    li.remove();

    self.dirty = true;
    self.trigger('change');
  };

  // saves entered translations to data model
  klass.prototype.save_item = function() { var self = this;
    self.modal.find('.translation input').each(function(){
      self.active_item.update_translation({field: 'name', locale: $(this).data('locale'), value: $(this).val()});
    });

    self.dirty = true;
    self.trigger('change');

    // render the item in the view
    var old_div = self.active_item.div; // may be undefined
    var new_div = self.render_item(self.active_item);
    if (self.modal_mode == 'new')
      self.ol.append($('<li>').html(new_div));
    else
      old_div.replaceWith(new_div);

    // done with this item
    self.active_item = null;

    self.modal.modal('hide');
  };

  // cancels the new/edit operation
  klass.prototype.cancel_edit = function() { var self = this;
    // done with this item
    self.active_item = null;
  };

  // returns number of items
  klass.prototype.count = function() { var self = this;
    return self.ol.find('li').length;
  };

  // registers event listeners
  klass.prototype.on = function(event_name, cb) { var self = this;
    if (!self.listeners[event_name])
      self.listeners[event_name] = [];

    self.listeners[event_name].push(cb);
  };

  // notifies listeners for the given event
  klass.prototype.trigger = function(event_name) { var self = this;
    var args = Array.prototype.slice.call(arguments).slice(1);
    (self.listeners[event_name] || []).forEach(function(f){
      f.apply(self, args);
    });
  };

  // returns a tree of items in the form:
  // [
  //   {item: {...}, children: [
  //     {item: {...}, children: [
  //       {item: {...}},
  //       {item: {...}},
  //       {item: {...}}
  //     ]},
  //     {item: {...}, children: [
  //       {item: {...}},
  //       {item: {...}}
  //     ]}
  //   ]}
  // ]
  klass.prototype.item_tree = function() { var self = this;
    return self.ol_to_tree(self.ol);
  };

  klass.prototype.ol_to_tree = function(ol) { var self = this;
    return ol.find('> li').map(function(){

      // get sub ol
      var sub_ol = $(this).find('> ol').first();

      // build the hash and recurse
      return {
        item: $(this).find('> div').data('item'),
        children: sub_ol.length > 0 ? self.ol_to_tree(sub_ol) : null
      };
    }).get();
  };

  // gets the number of top-level items in the list presently
  klass.prototype.size = function() { var self = this;
    return self.ol.find('> li').length;
  };

  // gets the maximum depth of any item in the list
  klass.prototype.max_depth = function() { var self = this;
    var max = 0;
    while (self.ol.find('li '.repeat(max + 1)).length > 0) max++;
    return max;
  };

  // checks to see if there is an item matching the given one
  klass.prototype.has_duplicate_of = function(item) { var self = this;
    return self.has_with_name(item.translation());
  };

  // checks if there is an item with the given name
  klass.prototype.has_with_name = function(name) { var self = this;
    var found = false;
    self.ol.find('div.inner').each(function(){
      if ($(this).data('item').translation() == name) {
        found = true;
        return false;
      }
    });
    return found;
  };

})(ELMO.Views);

