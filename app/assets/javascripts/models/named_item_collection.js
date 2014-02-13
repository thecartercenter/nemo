// ELMO.Models.NamedItemCollection
//
// Models a collection of named items such as options/optionings and option levels. Subclassed by OptioningCollection.
(function(ns, klass) {

  // constructor
  // item_class - (optional) the class to use when building items in the collection
  ns.NamedItemCollection = klass = function(item_class) { var self = this;

    // create an array for removed items
    self.removed = [];

    self.dirty = false;

    self.items = [];

    self.item_class = item_class || ELMO.Models.NamedItem;
  };

  // builds items objects from hashes of attributes
  klass.prototype.build_items = function(items_attribs) { var self = this;
    // create model objects for each item hash
    self.items = items_attribs.map(function(item_attribs){ return self.create_item(item_attribs); });

    // return self for nice chaining
    return self;
  };

  // creates an item object given a hash of attribs
  klass.prototype.create_item = function(attribs) { var self = this;
    attribs.parent = self;
    return new self.item_class(attribs);
  };

  // adds an item to the set
  klass.prototype.add = function(item) { var self = this;
    item.parent = self;
    self.items.push(item);
    self.dirty = true;
  };

  // removes a given item from the set
  klass.prototype.remove = function(item) { var self = this;
    var removed = self.items.splice(self.items.indexOf(item), 1);

    // if the removed item has an id, save it as it will need to be destroyed
    if (removed[0].id)
      self.removed.push(removed[0]);

    self.dirty = true;
  };

  // checks if this set currently has an option with the given name
  klass.prototype.has_with_name = function(name) { var self = this;
    for (var i = 0; i < self.items.length; i++)
      if (self.items[i].translation(I18n.defaultLocale) == name)
        return true;
    return false;
  };

  klass.prototype.get = function() { var self = this;
    return self.items;
  };

})(ELMO.Models);