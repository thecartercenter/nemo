#// Models an index table view as shown on most index pages.
class ELMO.Views.IndexTableView extends Backbone.View

  el: '#index_table'

  events:
    'click table.index_table tbody tr': 'row_clicked'
    'click #select_all_link': 'select_all_clicked'
    'click a.batch_op_link': 'submit_batch'
    'change input[type=checkbox].batch_op': 'checkbox_changed'
    'mouseover table.index_table tbody tr': 'highlight_partner_row'
    'mouseout table.index_table tbody tr': 'unhighlight_partner_row'

  initialize: (params) ->
    @no_whole_row_link = params.no_whole_row_link
    @form = this.$el.find('form').first() || this.$el.closest('form')
    @select_all_field = this.$el.find('input[name=select_all]')

    # flash the modified obj if given
    if params.modified_obj_id
      $('#' + params.class_name + '_' + params.modified_obj_id).effect("highlight", {}, 1000)

    # sync state of select all link
    if params.batch_ops
      this.update_select_all_link()

  # hook up whole row link unless told not to
  row_clicked: (event) ->
    return if @no_whole_row_link

    # go to the tr's href IF...
    # parent <td> is not .actions_col or .cb_col (to avoid misclick)
    return unless $(event.target).closest('td').is(':not(.actions_col, .cb_col)')

    # the parent <tr> is .clickable
    return unless $(event.currentTarget).is('.clickable')

    # target is not an <input>
    return unless event.target.tagName != 'INPUT'

    window.location.href = $(event.currentTarget).data('href')

  # add 'hovered' class to partner row if exists
  highlight_partner_row: (event) ->
    row = $(event.currentTarget)

    if (row.is('.second_row'))
      partner = row.prev()
    else
      partner = row.next('.second_row')

    if (partner.length > 0)
      partner.addClass('hovered')

  # remove 'hovered' class on mouseout
  unhighlight_partner_row: (event) ->
    $(event.target).closest('tbody').find('tr.hovered').removeClass('hovered')

  # selects/deselects all boxes
  select_all_clicked: (event) ->
    event.preventDefault() if event

    cbs = this.get_batch_checkboxes()

    all_checked = this.all_checked(cbs)

    # check/uncheck boxes
    cb.checked = !all_checked for cb in cbs

    # Set the value of the select_all field
    @select_all_field.val(if !all_checked then '1' else '')

    # update link
    this.update_select_all_link(all_checked)

    return false

  # tests if all boxes are checked
  all_checked: (cbs = this.get_batch_checkboxes()) ->
    _.all(cbs, (cb) -> cb.checked)

  # updates the select all link to reflect current state of boxes
  update_select_all_link: (yn = !this.all_checked()) ->
    label = I18n.t("layout." + (if yn then "select_all" else "deselect_all"))
    $('#select_all_link').html(label)

  # gets all checkboxes in batch_form
  get_batch_checkboxes: ->
    @form.find('input[type=checkbox].batch_op')

  # event handler for when a checkbox is clicked
  checkbox_changed: (event) ->
    # change text of link if all checked
    this.update_select_all_link()

  # submits the batch form to the given path
  submit_batch: (event) ->
    event.preventDefault()

    options = $(event.target).data()

    # ensure there is at least one box checked, and error if not
    count = _.size(_.filter(this.get_batch_checkboxes(), (cb) -> cb.checked))
    if count == 0
      alert(I18n.t("layout.no_selection"))

    # else, show confirm dialog (if requested), and proceed if 'yes' clicked
    else if not options.confirm or confirm(options.confirm.replace(/###/, count))

      # construct a temporary form
      form = $('<form>').attr('action', options.path).attr('method', 'post').attr('style', 'display: none')

      # copy the checked checkboxes to it, along with the select_all field
      # (we do it this way in case the main form has other stuff in it that we don't want to submit)
      form.append(@form.find('input.batch_op:checked').clone())
      form.append(@form.find('input[name=select_all]').clone())

      token = $('meta[name="csrf-token"]').attr('content');
      $('<input>').attr({type: 'hidden', name: 'authenticity_token', value: token}).appendTo(form)

      # need to append form to body before submitting
      form.appendTo($('body'))

      # submit the form
      form.submit()
