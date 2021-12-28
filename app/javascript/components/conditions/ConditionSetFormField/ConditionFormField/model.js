import queryString from 'query-string';
import { observable, action, reaction, computed } from 'mobx';

import { getLevelsValues, applyDefaultLevelsValues } from '../utils';

/**
 * Represents a single condition (e.g. 'Question Foo' Equals 'Bar').
 */
class ConditionModel {
  @observable
    id;

  @observable
    key;

  @observable
    optionSetId;

  @observable
    optionNodeId;

  /** Initial string value to represent the current option before `levels` are loaded. */
  @observable
    optionNodeValue;

  @observable
    leftQingId;

  @observable
    rightQingId;

  @observable
    op;

  @observable
    rightSideType;

  @observable
    operatorOptions = [];

  @observable
    value;

  @observable
    refableQings = [];

  @observable
    rightQingOptions = [];

  @observable
    levels = [];

  @observable
    remove;

  /**
   * Return a string representation of the current value.
   * Both user-facing and sent to the backend when performing a search.
   */
  @computed
  get currTextValue() {
    if (this.optionSetId) {
      const lastIndex = this.levels.length - 1;

      // Iterate back through each level, trying to find the deepest selected item.
      for (let i = lastIndex; i >= 0; i -= 1) {
        const { selected, options } = this.levels[i];

        if (selected != null) {
          const { name = '' } = options.find(({ id }) => selected === id) || {};
          return name;
        }
      }

      return null;
    } else if (this.optionNodeId) {
      // If optionSet hasn't been loaded (for example, if question filter popover
      // hasn't yet been mounted), fall back to the string value passed by backend.
      return this.optionNodeValue;
    }

    return this.value;
  }

  constructor(initialState = {}) {
    Object.assign(this, initialState);

    // Update levels when optionSet changes.
    reaction(
      () => this.optionSetId,
      async (optionSetId) => {
        if (optionSetId) {
          await this.updateLevels(null, optionSetId);
        }
      },
    );

    // Update rightQingOptions based on the selected leftQing, according to these rules:
    // - Don't show selected leftQing in rightQingOptions
    // - Allow only these type pairs:
    //   - textual type -> textual type
    //   - numeric type -> numeric type
    //   - select_multiple -> none (literals only, due to ODK restriction)
    //   - select_one -> others with same option set
    //   - exact match for all other question types (qtypes must be identical)
    reaction(
      () => this.leftQingId,
      (leftQingId) => {
        if (leftQingId) {
          const leftQing = this.refableQings.find((qing) => qing.id === leftQingId);
          this.rightQingOptions = this.refableQings.filter((rightQing) => {
            if (leftQing.id === rightQing.id || leftQing.qtypeName === 'select_multiple') return false;
            if (leftQing.textual) return rightQing.textual;
            if (leftQing.numeric) return rightQing.numeric;
            return leftQing.qtypeName === rightQing.qtypeName
              && leftQing.optionSetId === rightQing.optionSetId;
          });
        }
      },
      { fireImmediately: true },
    );
  }

  /**
   * Fetch data to populate the value for cascading selects.
   * nodeId may be null if there is no node selected.
   */
  @action
    updateLevels = async (changedNodeId = null, changedOptionSetId = null) => {
      const nodeId = changedNodeId || this.optionNodeId;
      const optionSetId = changedOptionSetId || this.optionSetId;

      if (!optionSetId) {
      // We don't have enough info yet to load values (probably mounting
      // a new component that will be updated momentarily).
        return;
      }

      ELMO.app.loading(true);
      const url = this.buildUrl(nodeId, optionSetId);
      try {
        if (process.env.NODE_ENV === 'test') return;

        const { levels } = await $.ajax(url);
        const oldValues = getLevelsValues(this.levels);
        this.levels = applyDefaultLevelsValues(levels, oldValues);
      } catch (error) {
        console.error('Failed to updateLevels:', error);
      } finally {
        ELMO.app.loading(false);
      }
    };

  buildUrl = (nodeId, optionSetId) => {
    const params = { node_id: nodeId || 'null', option_set_id: optionSetId };
    const url = ELMO.app.url_builder.build('condition-form-data', 'option-path');
    return `${url}?${queryString.stringify(params)}`;
  };
}

export default ConditionModel;
