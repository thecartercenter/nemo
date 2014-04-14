// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require core_ext/array
//= require core_ext/string
//= require core_ext/object
//= require jquery
//= require jquery_ujs
//= require jquery-ui-1.10.3.custom
//= require jquery.tokeninput
//= require jquery.mjs.nestedSortable-1.3.5
//= require jquery.spin
//= require core_ext/jquery_ext
//= require ckeditor/init
//= require ckeditor/adapters/jquery
//= require common
//= require sassafras/utils
//= require i18n
//= require i18n/translations
//= require bootstrap
//= require bootstrap-modal
//= require bootstrap-modalmanager

// some report superclasses need to come first due to inheritance
//= require views/control/control
//= require controllers/report/report_controller
//= require models/report/object_menu
//= require views/report/display
//= require views/report/edit_pane

//= require_tree .