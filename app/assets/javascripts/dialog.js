// ELMO.Dialog
(function(ns, klass) {
  
  // constructor
  ns.Dialog = klass = function(contents, options) {
    this.contents = contents;
    this.options = options ? options : {};

    // create and add div but don't show
    this.bg = $("<div>").addClass("dialog_bg").hide();
    this.bg.appendTo($("body")).after(this.contents.addClass("dialog").hide());
    
    // if dont_show is not set, show
    if (!this.options.dont_show) this.show();
    
    // hookup redraw event using currying
    (function(_this){ $(window).resize(function(){_this.redraw()}); })(this);

    this.redraw();
  }
  
  klass.prototype.show = function() {
    this.bg.show();
    this.contents.show();
  }
  
  klass.prototype.hide = function() {
    this.bg.hide();
    this.contents.hide();
  }
  
  klass.prototype.close = function() {
    this.bg.remove();
    this.contents.remove();
  }
  
  klass.prototype.redraw = function() {
    $("div.dialog_bg").width($(document).width()).height($(document).height());
    this.contents.css("top", ($(window).height() - this.contents.height()) / 2);
    this.contents.css("left", ($(window).width() - this.contents.width()) / 2);
  }
}(ELMO));