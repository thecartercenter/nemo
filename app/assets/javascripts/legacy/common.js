// namespaces
window.ELMO = {Report: {}, Control: {}, Views: {}, Models: {}};
window.Sassafras = {};

ELMO.LAT_LNG_REGEXP = /^(-?\d+(\.\d+)?)\s*[,;:\s]\s*(-?\d+(\.\d+)?)/

function logout() {
  // click the logout button
  if ($('#logout_button')) $('#logout_button').click();
}


// UTILITIES
(function (Utils, undefined) {
  // adds a name/value pair (e.g. "foo=bar") to a url; checks if there is already a query string
  Utils.add_url_param = function(url, param) {
    return url + (url.indexOf("?") == "-1" ? "?" : "&") + param;
  }

}(Utils = {}));

// JQUERY PLUGINS
jQuery.fn.selectText = function(){
    var doc = document
        , element = this[0]
        , range, selection
    ;
    if (doc.body.createTextRange) {
        range = document.body.createTextRange();
        range.moveToElementText(element);
        range.select();
    } else if (window.getSelection) {
        selection = window.getSelection();
        range = document.createRange();
        range.selectNodeContents(element);
        selection.removeAllRanges();
        selection.addRange(range);
    }
};

// IE 8 indexOf fix
if (!Array.prototype.indexOf)
{
  Array.prototype.indexOf = function(elt /*, from*/)
  {
    var len = this.length >>> 0;

    var from = Number(arguments[1]) || 0;
    from = (from < 0)
         ? Math.ceil(from)
         : Math.floor(from);
    if (from < 0)
      from += len;

    for (; from < len; from++)
    {
      if (from in this &&
          this[from] === elt)
        return from;
    }
    return -1;
  };
}

// IE 8 console fix
if (typeof console == "undefined") {
    window.console = {
        log: function () {}
    };
}

// jQuery plugin to prevent double submission of forms
// from: http://stackoverflow.com/questions/2830542/prevent-double-submission-of-forms-in-jquery
jQuery.fn.preventDoubleSubmission = function() {
  $(this).on('submit',function(e){
    var $form = $(this);

    if ($form.data('submitted') === true) {
      // Previously submitted - don't submit again
      e.preventDefault();
    } else {
      // Mark it so that the next submit can be ignored
      $form.data('submitted', true);
    }
  });

  // Keep chainability
  return this;
};

// Compares two arrays for equality.
Array.prototype.equalsArray = function (other) {
  if (this === other) return true;
  if (this == null || other == null) return false;
  if (this.length != other.length) return false;
  for (var i = 0; i < this.length; ++i) {
    if (this[i] !== other[i]) return false;
  }
  return true;
}
