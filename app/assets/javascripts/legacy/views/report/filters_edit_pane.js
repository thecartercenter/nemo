// ELMO.Report.FiltersEditPane < ELMO.Report.EditPane
(function (ns, klass) {
  // constructor
  ns.FiltersEditPane = klass = function (parent_view) {
    this.parent_view = parent_view;
    this.build();
  };

  // inherit from EditPane
  klass.prototype = new ns.EditPane();
  klass.prototype.constructor = klass;
  klass.prototype.parent = ns.EditPane.prototype;

  klass.prototype.id = 'filters';

  // builds controls
  klass.prototype.build = function () {
    // call super first
    this.parent.build.call(this);
  };

  klass.prototype.update = function (report) {
  };

  // extracts data from the view into the model
  klass.prototype.extract = function () {

  };
}(ELMO.Report));
