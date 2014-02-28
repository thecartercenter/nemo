// assorted jquery plugins
(function($) {

  // adds options to a select tag
  // options - an array of the form [["Option Name 1", "optval1"], ["Option Name 2", "optval2"], ...]
  $.fn.addOptions = function(opts) {
    // build an array of output pieces that form the option tags
    var output = [];
    opts.forEach(function(o) {
      output.push('<option value="', o[1], '">', o[0], '</option>');
    });

    // join the pieces and add to the select tag
    this.append(output.join(''));

    // return this to support chaining
    return this;
  }

  // removes all children except the first
  $.fn.emptyExceptFirst = function(opts) {
    this.find(":gt(0)").remove();
    return this;
  }
}(jQuery));


var serializeHash = function () {
    var attrs = {};

    $.each($(this).serializeArray(), function(i, field) {
        attrs[field.name] = field.value;
    });

    return attrs;
};

$.fn.extend({ serializeHash: serializeHash });
