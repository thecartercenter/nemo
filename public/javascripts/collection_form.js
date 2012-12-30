// ELMO.CollectionForm
(function(ns, klass) {
  
  // constructor
  ns.CollectionForm = klass = function(div) {
    this.div = div;
    
    // get highest item index
    this.max_index = this.div.find("div.items div.item").size() - 1;
    
    // get boilerplate html and delete
    var boilerplate = this.div.find("div.items div.item:first");
    this.boilerplate_html = boilerplate.clone().wrap("<p>").parent().html();
    boilerplate.remove();

    // hide any items with _destroy flag set
    (function(_this){ _this.div.find('input[id$="__destroy"][value="true"]').closest("div.item").each(
      function(){ _this.delete_item($(this)); })})(this);
    
    // hookup add link
    (function(_this){ _this.div.find("a.add_item_link").click(function(){ _this.add_item(); return false; }); })(this);
    
    // hookup all existing delete links
    this.hookup_delete_links(this.div);
    
    // hookup submit event
  }
  
  // class method to find and initialize all collection forms in document
  klass.init_all = function() {
    $("div.collection_form").each(function(){ new klass($(this)); });
  }
  
  // hooks up all delete links inside the given container
  klass.prototype.hookup_delete_links = function(container) {
    (function(_this){ container.find("a.delete_item_link").click(function(e){ 
      _this.delete_item($(e.target).closest("div.item")); 
      return false;
    }); })(this);
  }
  
  // adds a new item to the collection, based on the boilerplate
  klass.prototype.add_item = function() {
    // make boilerplate clone and set proper index
    var new_idx = ++this.max_index;
    var new_html = this.boilerplate_html.replace(/_0_/g, "_" + new_idx + "_").replace(/\[0\]/g, "[" + new_idx + "]");
    
    // append the new html
    this.div.find("div.items").append(new_html);
    
    // hookup the delete link
    this.hookup_delete_links(this.div.find("div.items div.item:last"));
  }
  
  // removes the given item
  klass.prototype.delete_item = function(item) {
    
    // hide the item
    item.hide();
    
    // set its delete flag
    item.find('input[id$="__destroy"]').val("true");
  }
  
}(ELMO));

$(document).ready(function(){ ELMO.CollectionForm.init_all(); });
