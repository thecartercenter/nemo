import cloneDeep from 'lodash/cloneDeep';
import isEqual from 'lodash/isEqual';
import { observable, action, reaction, computed } from 'mobx';

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

  /** Returns the number of non-deleted conditions in the set. */
  @computed
  get conditionCount() {
    return this.conditions.reduce((sum, condition) => sum + (condition.remove ? 0 : 1), 0);
  }

  /** Returns true if the user may have modified any values (conservative). */
  @computed
  get isDirty() {
    return !isEqual(this.original.conditions, this.conditions);
  }

  constructor(initialState = {}) {
    Object.assign(this, initialState);

    Object.assign(this.original, {
      conditions: cloneDeep(initialState.conditions) || [],
    });

    reaction(
      () => this.original.conditions,
      (conditions) => {
        this.original.conditions = this.prepareConditions(conditions);
      },
      { fireImmediately: true },
    );

    reaction(
      () => this.conditions,
      (conditions) => {
        this.conditions = this.prepareConditions(conditions);
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

  // Ensures conditions contains all instances of ConditionModel (and not plain objects)
  // Adds refableQings to the ConditionModels
  // Returns the original value if nothing is changed to avoid a reaction cycle.
  prepareConditions(conditions) {
    let changed = false;
    const newConditions = conditions.map((condition) => {
      if (!(condition instanceof ConditionModel)) {
        changed = true;
        return new ConditionModel({ ...condition, refableQings: this.refableQings });
      }
      if (!condition.refableQings) {
        changed = true;
        const fixedCondition = condition;
        fixedCondition.refableQings = this.refableQings;
        return fixedCondition;
      }
      return condition;
    });
    return changed ? newConditions : conditions;
  }

  @action
  addCondition = (defaultLeftQingToLast = false) => {
    this.conditions.push(new ConditionModel({
      leftQingId: defaultLeftQingToLast ? this.refableQings[this.refableQings.length - 1].id : null,
      refableQings: this.refableQings,
      key: Math.round(Math.random() * 100000000),
    }));
  }

  @action
  handleAddBlankCondition = () => {
    if (this.conditions.length === 0) {
      this.addCondition();
    }
  }
}

export default ConditionSetModel;
