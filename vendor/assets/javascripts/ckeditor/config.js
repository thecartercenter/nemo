/**
 * @license Copyright (c) 2003-2014, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.html or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function( config ) {
  // Define changes to default configuration here.
  // For the complete reference:
  // http://docs.ckeditor.com/#!/api/CKEDITOR.config

  // The toolbar groups arrangement, optimized for a single toolbar row.
  config.toolbarGroups = [
    //{ name: 'document',    groups: [ 'mode', 'document', 'doctools' ] },
    //{ name: 'clipboard',   groups: [ 'clipboard', 'undo' ] },
    //{ name: 'editing',     groups: [ 'find', 'selection', 'spellchecker' ] },
    //{ name: 'forms' },
    //{ name: 'paragraph',   groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ] },
    //{ name: 'insert' },    // Image, Flash, Table, Insert Horizontal Line, Smiley, Insert Special Character, Insert Page Break, IFrame
    //{ name: 'styles' },    // Styles, Format, Font, Size buttons
    //{ name: 'colors' },    // Text Color and Background Color buttons
    //{ name: 'tools' },     // Maximize and Show Blocks buttons
    //{ name: 'others' },    // no difference
    //{ name: 'about' }      // "?" icon
    { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
    { name: 'paragraph',   groups: [ 'list', 'indent' ]},
    { name: 'links' },     // Link, Unlink
    { name: 'document',    groups: [ 'mode' ]},
  ];

  // The default plugins included in the basic setup define some buttons that
  // we don't want too have in a basic editor. We remove them here.
  config.removeButtons = 'Cut,Copy,Paste,Undo,Redo,Anchor,Underline,Strike,Subscript,Superscript,Save,NewPage,Preview,Print';

  // Let's have it basic on dialogs as well.
  config.removeDialogTabs = 'link:advanced';
};
