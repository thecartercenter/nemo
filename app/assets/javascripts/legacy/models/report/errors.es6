// ELMO.Report.Errors
(function (ns, klass) {
  // constructor
  ns.Errors = klass = function (params) {
    this.errors_by_src = {};
    this.count = 0;
  };

  klass.prototype.add = function (src, msg) {
    this.count++;
    if (typeof (this.errors_by_src[src]) === 'undefined') this.errors_by_src[src] = [];
    this.errors_by_src[src].push(msg);
  };

  klass.prototype.get = function (src) {
    return this.errors_by_src[src] ? this.errors_by_src[src] : [];
  };

  klass.prototype.empty = function () {
    return this.count == 0;
  };
}(ELMO.Report));
