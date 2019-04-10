import { observable } from 'mobx';

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
  remove;

  constructor(initialValues) {
    Object.assign(this, initialValues);
  }
}

export default ConditionModel;
