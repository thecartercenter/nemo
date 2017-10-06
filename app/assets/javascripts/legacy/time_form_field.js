// ELMO.TimeFormField
//
// Models a datetime, date, or time type form field.
(function(ns, klass) {

  // constructor
  ns.TimeFormField = klass = function(container) {
    // save the container and get a ref to the select boxes
    this.container = container;
    this.selects = this.container.find("select");
  }

  // extracts the date/time value in a standardized string format (YYYY-MM-DD HH:MM)
  klass.prototype.extract_str = function() {
    // return empty string if any fields missing
    if (this.selects.map(function(){ return $(this).val() == ""; }).get().indexOf(true) != -1)
      return null;

    // figure out if this is a datetime, date, or time field
    // this is based on the known ID naming scheme for the rails date controls
    var type = this.selects.attr("id").match(/([a-z]+)_value_\di$/)[1];

    // init array for string pieces
    var str_bits = [];

    // get array of select values and pad any single digit values with a zero
    var vals = this.selects.map(function(){ return $(this).val().lpad("0", 2); }).get();

    // if there is a date portion, add the first three selects, separated by '-'
    if (type == "datetime" || type == "date")
      str_bits.push(vals.slice(0, 3).join("-"));

    // if there is a time portion, add the last three selects, separated by ':'
    if (type == "datetime" || type == "time")
      str_bits.push(vals.slice(-3).join(":"));

    return str_bits.join(" ");
  }
})(ELMO);
