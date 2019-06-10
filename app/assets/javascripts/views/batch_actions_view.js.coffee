#// Models the batch actions done on index pages
class ELMO.Views.BatchActionsView extends ELMO.Views.ApplicationView

  el: '#index_table'

  events:
    'click #select-all-link': 'select_all_clicked'
    'click a.select_all_pages': 'select_all_pages_clicked'
    'click a.batch_op_link': 'submit_batch'
    'change input[type=checkbox].batch_op': 'checkbox_changed'

  initialize: (params, search_form_view) ->
    @form = @$el.find('form').first() || @$el.closest('form')
    @select_all_pages_field = @$el.find('input[name=select_all_pages]')
    @alert = @$el.find('div.alert')
    @entries = @$el.data('entries')
    @class_name = I18n.t("activerecord.models.#{params.class_name}.many")
    @search_form_view = search_form_view
    @pages = @$el.data('pages')

    # flash the modified obj if given
    if params.modified_obj_id
      $('#' + params.class_name + '_' + params.modified_obj_id).effect("highlight", {}, 1000)

    if params.batch_ops
      @update_links()

  # selects/deselects all boxes on page
  select_all_clicked: (event) ->
    event.preventDefault()
    @toggle_all_boxes(!@all_checked())
    @set_select_all_pages_true_if_all_checked_and_only_one_page_else_false()
    @update_links()

  select_all_pages_clicked: (event) ->
    event.preventDefault()
    @select_all_pages_field.val('1')
    @update_links()

  checkbox_changed: (event) ->
    @set_select_all_pages_true_if_all_checked_and_only_one_page_else_false()
    @update_links()

  reset_alert: ->
    @alert.stop().hide().
      removeClass('alert-danger alert-info alert-warning alert-success').removeAttr('opacity')

  # Updates the select all link and the select all pages notice.
  update_links: ->
    label = if @all_checked() then "deselect_all" else "select_all"
    $('#select-all-link').html(I18n.t("layout.#{label}"))

    @reset_alert()

    if @select_all_pages_field.val()
      msg = I18n.t("index_table.messages.selected_all_rows", {class_name: @class_name, count: @entries})
      @alert.html(msg)
      @alert.addClass('alert-info').show()
    else if @pages > 1 && @all_checked()
      msg = I18n.t("index_table.messages.selected_rows_page",
        {class_name: @class_name, count: @get_selected_count()}) + " " +
        "<a href='#' class='select_all_pages'>" +
        I18n.t("index_table.messages.select_all_rows", {class_name: @class_name, count: @entries}) +
        "</a>"
      @alert.html(msg)
      @alert.addClass('alert-info').show()

  # gets all checkboxes in batch_form
  get_batch_checkboxes: ->
    @form.find('input[type=checkbox].batch_op')

  get_selected_count: ->
    if @select_all_pages_field.val()
      @entries
    else
      _.size(_.filter(@get_batch_checkboxes(), (cb) -> cb.checked))

  get_selected_items: ->
    @form.find('input.batch_op:checked')

  toggle_all_boxes: (bool) ->
    cbs = @get_batch_checkboxes()
    cb.checked = bool for cb in cbs

  # tests if all boxes are checked
  all_checked: (cbs = @get_batch_checkboxes()) ->
    _.all(cbs, (cb) -> cb.checked)

  set_select_all_pages_true_if_all_checked_and_only_one_page_else_false: ->
    @select_all_pages_field.val(if @all_checked() && @pages == 1 then '1' else '')

  # submits the batch form to the given path
  submit_batch: (event) ->
    event.preventDefault()

    options = $(event.target).data()

    # ensure there is at least one item selected, and error if not
    selected = @get_selected_count()
    if selected == 0
      @alert.html(I18n.t("layout.no_selection")).addClass('alert-danger').show()
      @alert.delay(2500).fadeOut('slow', @reset_alert.bind(this))

    # else, show confirm dialog (if requested), and proceed if 'yes' clicked
    else if not options.confirm or confirm(I18n.t(options.confirm, {count: selected}))

      # construct a temporary form
      form = $('<form>').attr('action', options.path).attr('method', 'post').attr('style', 'display: none')

      # copy the checked checkboxes to it, along with the select_all field
      # (we do it this way in case the main form has other stuff in it that we don't want to submit)
      form.append(@form.find('input.batch_op:checked').clone())
      form.append(@form.find('input[name=select_all_pages]').clone())
      pages_field = @form.find('input[name=pages]')
      pages_field.val(@pages)
      form.append(pages_field.clone())
      if (@search_form_view)
        form.append(@search_form_view.$el.find('input[name=search]').clone())

      token = $('meta[name="csrf-token"]').attr('content')
      $('<input>').attr({type: 'hidden', name: 'authenticity_token', value: token}).appendTo(form)

      form.appendTo($('body'))
      form.submit()

    return false
