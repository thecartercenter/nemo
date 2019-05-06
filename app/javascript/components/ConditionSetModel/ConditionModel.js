import queryString from 'query-string';
import { observable, action, reaction, computed } from 'mobx';

import { getLevelsValues, applyDefaultLevelsValues } from './utils';

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
  refQingId;

  @observable
  op;

  @observable
  operatorOptions = [];

  @observable
  value;

  @observable
  levels = [];

  @observable
  remove;

  constructor(initialValues) {
    Object.assign(this, initialValues);

    // Update levels when optionSet changes.
    reaction(
      () => this.optionSetId,
      async (optionSetId) => {
        if (optionSetId) {
          await this.updateLevels(null, optionSetId);
        }
      },
    );
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
    const params = { node_id: nodeId || 'null' };
    const url = ELMO.app.url_builder.build('option-sets', optionSetId, 'condition-form-view');
    return `${url}?${queryString.stringify(params)}`;
  }
}

export default ConditionModel;
