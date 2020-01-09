String.prototype.underscore_to_camel = function () {
  return this.replace(/_[a-z]/, (m) => { return m.substring(1).toUpperCase(); });
};

String.prototype.capitalize = function () {
  return this.replace(/^[a-z]/, (m) => { return m.toUpperCase(); });
};

String.prototype.repeat = function (num) {
  return new Array(num + 1).join(this);
};
