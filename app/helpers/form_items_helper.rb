module FormItemsHelper
  def item_rank(item, parent_rank)
    parent_rank.blank? ? item.rank : "#{parent_rank}.#{item.rank}"
  end
end
