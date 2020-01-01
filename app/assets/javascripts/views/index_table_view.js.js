#// Models an index table view as shown on most index pages.
class ELMO.Views.IndexTableView extends ELMO.Views.ApplicationView

  el: '#index_table'

  events:
    'click table.index_table tbody tr': 'row_clicked'
    'mouseover table.index_table tbody tr': 'highlight_partner_row'
    'mouseout table.index_table tbody tr': 'unhighlight_partner_row'

  initialize: (params) ->
    @no_whole_row_link = params.no_whole_row_link

    # flash the modified obj if given
    if params.modified_obj_id
      $('#' + params.class_name + '_' + params.modified_obj_id).effect("highlight", {}, 1000)

  # hook up whole row link unless told not to
  row_clicked: (event) ->
    return if @no_whole_row_link

    # go to the tr's href IF...
    # parent <td> is not .action or .cb_col (to avoid misclick)
    return unless $(event.target).closest('td').is(':not(.action, .cb_col)')

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
