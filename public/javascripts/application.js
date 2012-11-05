// namespaces
var ELMO = {Report: {}, Control: {}};
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