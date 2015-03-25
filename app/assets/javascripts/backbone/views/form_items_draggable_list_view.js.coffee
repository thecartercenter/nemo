# Controls draggable list behavior for form items list.
class ELMO.Views.FormItemsDraggableListView extends Backbone.View

  el: '.form-items-list'

  initialize: (params) ->
    this.parent_view = params.parent_view

    $('.item-list').nestedSortable
      handle: 'div',
      items: 'li',
      toleranceElement: '> div',
      forcePlaceholderSize: true,
      placeholder: 'placeholder',
      isAllowed: (placeholder, parent, item) =>
        this.drop_target_is_allowed(placeholder, parent, item)
      update: (event, ui) =>
        this.drop_happened(event, ui)

  drop_target_is_allowed: (placeholder, parent, item) ->
    # Must be undefined parent or group type.
    allowed = !parent || parent.hasClass('form-item-group')

    # If group, must be depth 1, else must be depth 1 or 2.
    if allowed
      depth = this.get_depth(placeholder)
      allowed = if item.hasClass('form-item-group') then depth == 1 else depth <= 2

    # If not allowed, show the placeholder border as red.
    $('.form-items .placeholder').css('border-color', if allowed then '#aaa' else 'red')

    # Return
    allowed

  # Called at the end of a drag. Saves new position.
  drop_happened: (event, ui) ->
    this.update_condition_refs()
    this.parent_view.update_item_position(ui.item.data('id'), this.get_parent_id_and_rank(ui.item))

  # Gets the parent_id (or null if top-level) and rank of the given li.
  get_parent_id_and_rank: (li) ->
    parent = li.parent().closest('li.form-item')
    {
      parent_id: if parent.length then parent.data('id') else null,
      rank: li.prevAll('li.form-item').length + 1
    }

  # Gets the fully qualified rank of the given item/li.
  get_full_rank: (li) ->
    path = li.parents('li.form-item').andSelf()
    ranks = path.map -> $(this).prevAll('li.form-item').length + 1
    ranks.get().join('.')

  get_depth: (li) ->
    li.parents('li.form-item').length + 1

  # Updates any condition cross-references after a drop or delete.
  update_condition_refs: ->
    @$(".condition").each (i, cond) =>
      cond = $(cond)
      refd = @$("li.form-item[data-id=#{cond.data('ref-id')}]")
      if refd.length
        cond.find('span').html(this.get_full_rank(refd))
      else
        cond.remove()
