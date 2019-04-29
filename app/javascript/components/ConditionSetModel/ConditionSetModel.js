import { observable, action, reaction } from 'mobx';

import ConditionModel from './ConditionModel';

/**
 * Represents a set of conditions (e.g. ['Question Foo' Equals 'Bar', ...]).
 */
class ConditionSetModel {
  @observable
  formId;

  @observable
  namePrefix;

  @observable
  originalConditions = [];

  @observable
  conditions = [];

  @observable
  conditionableId;

  @observable
  conditionableType;

  @observable
  refableQings = [];

  @observable
  hide;

  constructor(initialValues = {}) {
    // Make sure conditions are always instances of the model.
    // TODO: MobX-state-tree can do this automatically for us.
    reaction(
      () => this.originalConditions,
      (originalConditions) => {
        this.originalConditions = this.mapConditionsToStores(originalConditions);
      },
    );
    reaction(
      () => this.conditions,
      (conditions) => {
        this.conditions = this.mapConditionsToStores(conditions);
      },
    );

    Object.assign(this, initialValues);

    if (!initialValues.hide) {
      this.handleAddBlankCondition();
    }

    // If about to show the set and it's empty, add a blank condition.
    reaction(
      () => this.hide,
      (hide) => {
        if (!hide) {
          this.handleAddBlankCondition();
        }
      },
    );
  }

  mapConditionsToStores(conditions) {
    // Only modify if necessary to prevent a cycle.
    if (conditions.some((condition) => !(condition instanceof ConditionModel))) {
      return conditions.map((condition) => new ConditionModel(condition));
    }
    return conditions;
  }

  @action
  handleAddClick = () => {
    this.conditions.push(new ConditionModel({
      key: Math.round(Math.random() * 100000000),
    }));
  }

  @action
  handleAddBlankCondition = () => {
    if (this.conditions.length === 0) {
      this.handleAddClick();
    }
  }
}

export default ConditionSetModel;
