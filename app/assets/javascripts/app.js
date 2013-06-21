// ELMO.App
//
// handles general client side stuff that appears in the template (e.g. language chooser form)
(function(ns, klass) {

  // constructor
  ns.App = klass = function() { var self = this;

    // setup the language change form and link
    $("a#locale_form_link").on("click", function(){ $("#locale_form").css("display", "inline-block"); $(this).hide(); return false; });
    $("#locale_form select").on("change", function(){ self.change_locale($(this).val()); return false; });
  }

  // changes the current locale by rewriting the url to use the new locale
  klass.prototype.change_locale = function(new_locale) { var self = this;    
    // get the new path with the locale stripped
    var path = self.strip_locale(window.location.pathname).replace();
    
    // build a new url and go there
    window.location.href = Utils.build_url(path, {locale: new_locale});
  }
  
  // strips any locale information from the given path
  // "/en/foo" => "/foo"; "/foo" => "/foo"; "/en/" => "/"; "/en" => "/"; "/" => "/", "" => "/";
  klass.prototype.strip_locale = function(path) {
    // replace the "/en/", "/en", "/" variants with ""
    if (path == "" || path.match(/^\/([a-z]{2}(\/)?)?$/))
      return "/";
    // else fix the "/en/foo" variants
    else
      return path.replace(/^\/[a-z]{2}\/(.+)/, function(m, $1){ return "/" + $1; });
  }
  
})(ELMO);
