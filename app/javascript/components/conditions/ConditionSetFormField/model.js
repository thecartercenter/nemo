import cloneDeep from 'lodash/cloneDeep';
import { observable, action, reaction } from 'mobx';

import ConditionModel from './ConditionFormField/model';

/**
 * Represents a set of conditions (e.g. ['Question Foo' Equals 'Bar', ...]).
 */
class ConditionSetModel {
  /** Deep copy of this model's original values (e.g. to enable reverting). */
  @observable
  original = new Map();

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
  hide;

  @observable
  showQingRank = true;

  /** If enabled, only allow 'equals' or 'includes' as the operation. */
  @observable
  forceEqualsOp = false;

  /** If enabled, only allow literals on right side of all conditions. */
  @observable
  forceRightSideLiteral = false;

  constructor(initialState = {}) {
    Object.assign(this, initialState);

    Object.assign(this.original, {
      conditions: cloneDeep(initialState.conditions) || [],
    });

    // Make sure conditions are always instances of the model.
    // TODO: MobX-state-tree can do this automatically for us.
    reaction(
      () => this.original,
      (original) => {
        this.original.conditions = this.mapConditionsToStores(original.conditions);
      },
      { fireImmediately: true },
    );
    reaction(
      () => this.conditions,
      (conditions) => {
        this.conditions = this.mapConditionsToStores(conditions);
      },
      { fireImmediately: true },
    );

    // If about to show the set and it's empty, add a blank condition.
    reaction(
      () => this.hide,
      (hide) => {
        if (!hide) {
          this.handleAddBlankCondition();
        }
      },
      { fireImmediately: true },
    );
  }

  mapConditionsToStores(conditions) {
    // Only modify if necessary to prevent a cycle.
    if (conditions.some((condition) => !(condition instanceof ConditionModel))) {
      return conditions.map((condition) => {
        condition.refableQings = this.refableQings;
        return new ConditionModel(condition);
      });
    }
    return conditions;
  }

  @action
  handleAddClick = () => {
    this.conditions.push(new ConditionModel({
      refableQings: this.refableQings,
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
