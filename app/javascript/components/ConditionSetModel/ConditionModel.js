import queryString from 'query-string';
import { observable, action, reaction } from 'mobx';

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
          await this.updateLevels();
        }
      },
    );
  }

  /**
   * Fetch data to populate the value for cascading selects.
   * nodeId may be null if there is no node selected.
   */
  @action
  updateLevels = async (changedNodeId = null) => {
    ELMO.app.loading(true);
    const url = this.buildUrl(changedNodeId);
    try {
      const { levels } = await $.ajax(url);
      const oldValues = getLevelsValues(this.levels);
      this.levels = applyDefaultLevelsValues(levels, oldValues);
    } catch (error) {
      console.error('Failed to updateLevels:', error);
    } finally {
      ELMO.app.loading(false);
    }
  }

  buildUrl = (changedNodeId = null) => {
    const params = { node_id: changedNodeId || this.optionNodeId };
    const url = ELMO.app.url_builder.build('option-sets', this.optionSetId, 'condition-form-view');
    return `${url}?${queryString.stringify(params)}`;
  }
}

export default ConditionModel;
