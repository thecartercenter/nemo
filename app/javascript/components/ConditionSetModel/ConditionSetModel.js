import { observable, action } from 'mobx';

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
}

export default ConditionSetModel;
