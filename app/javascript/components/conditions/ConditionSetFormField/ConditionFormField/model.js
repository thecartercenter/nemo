import queryString from 'query-string';
import { observable, action, reaction, computed } from 'mobx';

import { getLevelsValues, applyDefaultLevelsValues } from '../utils';
import cloneDeep from 'lodash/cloneDeep';

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

  constructor(initialValues = {}) {
    this.initialize(initialValues);

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
          const leftQing = this.refableQings.find((qing) => qing.id == leftQingId);
          this.rightQingOptions = this.refableQings.filter((rightQing) => {
            if (leftQing.id == rightQing.id || leftQing.qtype_name == 'select_multiple') {
              return false;
            } else if (leftQing.textual) {
              return rightQing.textual;
            } else if (leftQing.numeric) {
              return rightQing.numeric;
            } else {
              return leftQing.qtypeName == rightQing.qtypeName
                && leftQing.optionSetId == rightQing.optionSetId;
            }
          });
        }
      },
      { fireImmediately: true },
    );

  }

  // Initial values may not be known at the time the store is created.
  // This method can be used to set the initial values at a later point.
  @action
  initialize = (initialValues) => {
    Object.assign(this, initialValues);
  }

  /** Return either the current value or the value of the deepest defined level. */
  @computed
  get currTextValue() {
    if (this.optionSetId) {
      const lastIndex = this.levels.length - 1;

      for (let i = lastIndex; i >= 0; i -= 1) {
        const { selected, options } = this.levels[i];

        if (selected != null) {
          const { name = '' } = options.find(({ id }) => selected === id) || {};
          return name;
        }
      }

      return null;
    }

    return this.value;
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
  }

  buildUrl = (nodeId, optionSetId) => {
    const params = { node_id: nodeId || 'null', option_set_id: optionSetId };
    const url = ELMO.app.url_builder.build('condition-form', 'option-path');
    return `${url}?${queryString.stringify(params)}`;
  }
}

export default ConditionModel;
