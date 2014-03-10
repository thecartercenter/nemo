module OptioningParentable
  extend ActiveSupport::Concern

  # checks if any options have been added since last save
  def options_added?
    is_a?(Optioning) && new_record? || optionings.any?(&:options_added?)
  end

  # checks if any options have been removed since last save
  # relies on the the marked_for_destruction field since this method is used by the controller
  def options_removed?
    is_a?(Optioning) && marked_for_destruction? || optionings.any?(&:options_removed?)
  end

  # checks if any of the options in this set have changed position (rank or parent) since last save
  # trivially true if this is a new object
  def positions_changed?
    # first check self (unless self is an OptionSet), then check children if necessary
    is_a?(Optioning) && signature_changed? || optionings.any?(&:positions_changed?)
  end

  # returns the parent, either an OptionSet or Optioning, or nil if self is an OptionSet
  def _parent
    is_a?(OptionSet) ? nil : (parent || option_set)
  end

  # gets all descendants of this node
  def descendants
    (optionings + optionings.map(&:descendants)).flatten
  end

  # recursively updates children based on attrib array of form:
  # [
  #   {
  #     'option' => {
  #       'name_translations' => {'en' => 'Animal'}
  #     },
  #     'optionings' => [
  #       {
  #         'option' => {
  #           'name_translations' => {'en' => 'Cat'}
  #         }
  #       },
  #       {
  #         'option' => {
  #           'id' => dog.id
  #         }
  #       }
  #     ]
  #   },
  #   {
  #     'option' => {
  #       'name_translations' => {'en' => 'Plant'}
  #     },
  #     'optionings' => [
  #       {
  #         'option' => {
  #           'name_translations' => {'en' => 'Tulip'}
  #         }
  #       },
  #       {
  #         'option' => {
  #           'id' => oak.id,
  #           # also change a name for this option
  #           'name_translations' => {'en' => 'White Oak'}
  #         }
  #       }
  #     ]
  #   }
  # ]
  #
  # optioning_data - the array
  # option_set - the parent option set
  # depth - the current recursion depth
  def update_children_from_json(optioning_data, option_set, depth)
    # puts "UPDATING #{is_a?(OptionSet) ? 'root' : option.name} depth #{depth} with"
    # pp optioning_data

    # if optioning_data is a hash just take the values
    optioning_data = optioning_data.values if optioning_data.is_a?(Hash)
    optioning_data ||= []

    optioning_data.each_with_index do |json, idx|
      # if this is a new optioning, build it
      if json['id'].nil?
        optioning = optionings.build(
          :mission => option_set.mission,
          :option_set => option_set
        )
        optioning.parent = self unless is_a?(OptionSet)

      # else, we need to lookup the optioning in the tree
      else
        optioning = option_set.all_optionings_by_id[json['id'].to_i]
        raise 'invalid optioning ID given in JSON' if optioning.nil?
      end

      # if we are destroying, destroy
      if json['_destroy']

        optioning.remove_and_destroy

      else

        # move to new parent if necessary
        optioning.move_to(self) unless optioning._parent == self

        # set the proper option level
        optioning.option_level = option_set.multi_level? ? option_set.option_levels[depth - 1] : nil

        # set the rank incrementally
        optioning.rank = idx + 1

        # build/find the option
        option = if id = json['option']['id']
          # if the optioning's current option already has the given ID, do nothing, just return
          optioning.option = Option.find(id) unless optioning.option_id == id.to_i
          optioning.option
        else
          optioning.build_option(:mission => option_set.mission)
        end

        # update the option translations if given
        option.name_translations = json['option']['name_translations'] if json['option']['name_translations']

        # update children, if given
        optioning.update_children_from_json(json['optionings'], option_set, depth + 1) if json['optionings']

      end
    end
  end

  # destroys all descendants then destroys self
  def destroy_with_descendants
    optionings.each{|o| o.destroy_with_descendants}
    destroy
  end

  protected
    # makes sure, recursively, that the options in the set have sequential ranks starting at 1.
    def ensure_children_ranks
      optionings.ensure_contiguous_ranks
      optionings.each{|c| c.ensure_children_ranks}
    end
end