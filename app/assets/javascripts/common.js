// namespaces
var ELMO = {Report: {}, Control: {}, Views: {}, Models: {}};
var Sassafras = {};

ELMO.LAT_LNG_REGEXP = /^(-?\d+(\.\d+)?)\s*[,;:\s]\s*(-?\d+(\.\d+)?)/

// pads strings to the left
String.prototype.lpad = function(pad_str, length) {
  var str = this;
  while (str.length < length) str = pad_str + str;
  return str;
}

// pads strings to the right
String.prototype.rpad = function(pad_str, length) {
  var str = this;
  while (str.length < length) str = str + pad_str;
  return str;
}

// hookup mission dropdown box to submit form
$(document).ready(function(){ $("select#user_current_mission_id").change(function(e){
  // show loading indicator
  $(e.target).parents("form").find("div.loading_indicator img").show();

  // submit form
  $(e.target).parents("form").submit();
}) });

// ruby-like collect
(function($) {
    $.fn.collect = function(callback) {
        if (typeof(callback) == "function") {
            var collection = [];

            $(this).each(function() {
                var item = callback.apply(this);

                if (item)
                    collection.push(item);
            });

            return collection;
        }

        return this;
    }
})(jQuery);


function logout() {
  // click the logout button
  if ($('#logout_button')) $('#logout_button').click();
}


// UTILITIES
(function (Utils, undefined) {
  Utils.show_flash = function(params) {
    Utils.clear_flash();
    $(".status_messages").append($("<div>").addClass(params.type).text(params.msg));
    if (params.hide_after)
      setTimeout(Utils.clear_flash, params.hide_after * 1000);
  }

  Utils.clear_success_flash_after_delay = function() {
    setTimeout(function(){$(".alert-success").remove();}, 5000);
  }

  Utils.clear_flash = function(params) {
    $(".success").remove();
    $(".error").remove();
  }

  Utils.array_eq = function(a, b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) if (a[i] != b[i]) return false;
    return true;
  }

  // adds a name/value pair (e.g. "foo=bar") to a url; checks if there is already a query string
  Utils.add_url_param = function(url, param) {
    return url + (url.indexOf("?") == "-1" ? "?" : "&") + param;
  }

  // builds a URL by adding the locale and maintaining admin mode
  // last arg can optionally specify the locale, e.g. {locale: "fr"}
  Utils.build_path = function() {
    // we need some funky magic to turn the arguments object into an array
    var args = Array.prototype.slice.call(arguments, 0);
    var options = {};

    // if the last arg is an options hash, extract it
    if (typeof(args[args.length-1]) == "object") {
      options = args[args.length-1];
      args = args.slice(0, args.length-1);
    }

    // default to the current locale
    if (!options.locale) options.locale = I18n.locale;

    // admin chunk
    var admin_chunk = ELMO.app.params.admin_mode ? '/admin' : '';

    // return, fixing any double slashes
    return ("/" + options.locale + admin_chunk + "/" + args.join("/")).replace(/[\/]{2,}/g, "/");
  }

  // strips any locale and admin-mode information from the given path
  // "/en/foo" => "/foo"; "/foo" => "/foo"; "/en/" => "/"; "/en" => "/"; "/" => "/", "" => "/";
  // "/en/admin/foo" => "/foo"; "/en/admin" => "/"; "/en/admin/" => "/"
  Utils.strip_path = function(path) {
    // replace the "/en/", "/en/admin", "/en/admin/", "/en", and "/" variants with "/"
    if (path == "" || path.match(/^\/([a-z]{2}(\/admin)?(\/)?)?$/))
      return "/";
    // else fix the "/en/foo" or "/en/admin/foo" variants
    else
      return path.replace(/^\/[a-z]{2}(\/admin)?\/(.+)/, function(m, $1, $2){ return "/" + $2; });
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