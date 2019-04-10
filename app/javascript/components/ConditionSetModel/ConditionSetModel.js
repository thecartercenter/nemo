import { observable, action, reaction } from 'mobx';

/**
 * Represents a set of conditions (e.g. ['Question Foo' Equals 'Bar', ...]).
 */
class ConditionSetModel {
  @observable
  formId;

  @observable
  namePrefix;

  @observable
  conditions = [];

  @observable
  conditionableId;

  @observable
  conditionableType;

  @observable
  refableQings = [];

  @observable
  hide = false;

  constructor() {
    // If about to show the set and it's empty, add a blank condition.
    reaction(
      () => this.hide,
      (hide) => {
        if (!hide) this.handleAddBlankCondition();
      },
    );
  }

  @action
  handleAddClick = () => {
    const { formId, conditions, refableQings, conditionableId, conditionableType } = this;

    this.conditions = conditions.concat([{
      key: Math.round(Math.random() * 100000000),
      formId,
      refableQings,
      operatorOptions: [],
      conditionableId,
      conditionableType,
    }]);
  }

  @action
  handleAddBlankCondition = () => {
    if (this.conditions.length === 0) {
      this.handleAddClick();
    }
  }
}

export default ConditionSetModel;
