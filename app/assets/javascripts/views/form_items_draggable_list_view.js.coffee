# Controls draggable list behavior for form items list.
class ELMO.Views.FormItemsDraggableListView extends ELMO.Views.ApplicationView

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
    reason = null

    # Must be undefined parent or group type.
    if parent && !parent.hasClass('form-item-group')
      reason = 'parent_must_be_group'

    else if !this.check_condition_order(placeholder, item)
      reason = 'invalid_condition'

    # Show the reason if applicable.
    html = if reason then '<div>' + I18n.t("form.invalid_drop_location.#{reason}") + '</div>' else ''
    placeholder.html(html)

    !reason

  # Called at the end of a drag. Saves new position.
  drop_happened: (event, ui) ->
    this.update_condition_refs()
    this.parent_view.update_action_icons()
    this.parent_view.update_item_position(ui.item.data('id'), this.get_parent_id_and_rank(ui.item))

  # Gets the parent_id (or null if top-level) and rank of the given li.
  get_parent_id_and_rank: (li) ->
    parent = li.parent().closest('li.form-item')
    {
      parent_id: if parent.length then parent.data('id') else null,
      rank: li.prevAll('li.form-item').length + 1
    }

  # Gets the fully qualified rank, as an array of integers, of the given item/li.
  get_full_rank: (li) ->
    path = li.parents('li.form-item, li.placeholder').andSelf()
    ranks = path.map -> $(this).prevAll('li.form-item, li.placeholder').length + 1
    ranks.get()

  # Updates any condition cross-references after a drop or delete.
  update_condition_refs: ->
    @$(".condition").each (i, cond) =>
      cond = $(cond)
      refd = @$("li.form-item[data-id=#{cond.data('ref-id')}]")
      if refd.length
        cond.find('span').html(this.get_full_rank(refd).join('.'))
      else
        cond.remove()

  # Checks if the given position (indicated by placeholder) for the given item, or any of its children,
  # would invalidate any conditions.
  # Returns false if invalid.
  check_condition_order: (placeholder, item) ->
    # If item or any children refer to questions, the placeholder must be after all the referred questions.
    for c in item.find('.refd-qing')
      refd = @$("li.form-item[data-id=#{$(c).data('ref-id')}]")
      return false unless this.compare_ranks(placeholder, refd) == 1

    # If item, or any children, are referred to by one or more questions,
    # the placeholder must be before all the referring questions.
    child_ids = item.find('.form-item').andSelf().map -> $(this).data('id')
    for id in child_ids.get()
      for refd_qing in @$(".refd-qing[data-ref-id=#{id}]") # Loop over all matching refd_qings
        referrer = $(refd_qing.closest('li.form-item'))
        return false unless this.compare_ranks(placeholder, referrer) == -1

    true

  # Compares ranks of two items, returning 1 if a > b, 0 if a == b, -1 if a < b
  compare_ranks: (a, b) ->
    ar = this.get_full_rank(a)
    br = this.get_full_rank(b)
    for _, i in ar
      if ar[i] > br[i]
        return 1
      else if ar[i] < br[i]
        return -1

    # If we get to this point, all ranks so far have been equal.
    # If both a and b are same length, we can return 0. Else,
    # the greater rank is the longer one.
    if ar.length == br.length then 0 else if ar.length > br.length then 1 else -1
