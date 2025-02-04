import isEmpty from 'lodash/isEmpty';
import cloneDeep from 'lodash/cloneDeep';
import isEqual from 'lodash/isEqual';
import moment from 'moment';
import { action, observable, computed, reaction, toJS } from 'mobx';

import ConditionSetModel from '../conditions/ConditionSetFormField/model';
import { SUBMITTER_TYPES } from './SubmitterFilter/utils';

/** Empty model to be used for resetting the store as needed. */
const initialConditionSetData = Object.freeze(toJS(new ConditionSetModel({
  namePrefix: 'questioning[display_conditions_attributes]',
  conditionableType: 'FormItem',
  hide: false,
  forceEqualsOp: true,
  forceRightSideLiteral: true,
  showQingRank: false,
})));

/** Map from each type to an empty array. */
export const getEmptySubmitterTypeMap = () => SUBMITTER_TYPES.reduce((reduction, type) => {
  // eslint-disable-next-line no-param-reassign
  reduction[type] = [];
  return reduction;
}, {});

class FiltersModel {
  /** Deep copy of this model's original values (e.g. to enable reverting). */
  @observable
    original = {};

  @observable
    conditionSetStore = new ConditionSetModel(initialConditionSetData);

  @observable
    allForms = [];

  @observable
    selectedFormIds = [];

  @observable
    isReviewed = null;

  @observable
    selectedSubmittersForType = getEmptySubmitterTypeMap();

  @observable
    advancedSearchText = '';

  @observable
    startDate = null;

  @observable
    endDate = null;

  @computed
  get selectedFormId() {
    return isEmpty(this.selectedFormIds) ? '' : this.selectedFormIds[0];
  }

  /** Returns true if the user may have modified any values (conservative). */
  @computed
  get isDirty() {
    const clean = (
      isEqual(this.original.selectedFormIds, this.selectedFormIds)
      && isEqual(this.original.isReviewed, this.isReviewed)
      && isEqual(this.original.selectedSubmittersForType, this.selectedSubmittersForType)
      && isEqual(this.original.startDate, this.startDate)
      && isEqual(this.original.endDate, this.endDate)
      && !this.conditionSetStore.isDirty
    );
    return !clean;
  }

  constructor(initialState = {}) {
    const { selectedQings, startDate, endDate } = initialState;

    // Convert dates to moment if given.
    if (startDate) {
      // eslint-disable-next-line no-param-reassign
      initialState.startDate = moment(startDate);
    }
    if (endDate) {
      // eslint-disable-next-line no-param-reassign
      initialState.endDate = moment(endDate);
    }

    // If any qings should be selected, create new conditions for them.
    if (!isEmpty(selectedQings)) {
      this.conditionSetStore.resetConditionsFromQings(selectedQings);

      // No longer needed now that conditions have been created.
      // eslint-disable-next-line no-param-reassign
      delete initialState.selectedQings;
    }

    Object.assign(this, initialState);

    Object.assign(this.original, {
      selectedFormIds: cloneDeep(initialState.selectedFormIds) || [],
      // Convert undefined to null for consistency, since this is a tri-state boolean.
      isReviewed: initialState.isReviewed == null ? null : initialState.isReviewed,
      selectedSubmittersForType: cloneDeep(initialState.selectedSubmittersForType) || getEmptySubmitterTypeMap(),
      startDate: initialState.startDate,
      endDate: initialState.endDate,
    });

    // Update conditionSet IDs when selected forms change.
    reaction(
      () => this.selectedFormId,
      async (selectedFormId) => {
        if (this.conditionSetStore.formId !== selectedFormId) {
          // Reset the store because the available questions will have changed.
          Object.assign(this.conditionSetStore, new ConditionSetModel(initialConditionSetData), {
            original: this.conditionSetStore.original,
          });

          await this.updateRefableQings();
        }
      },
    );
  }

  @action
    updateRefableQings = async () => {
      ELMO.app.loading(true);
      const url = ELMO.app.url_builder.build('filter-data', 'qings');
      try {
        if (process.env.NODE_ENV === 'test') return;
        const qings = await $.ajax({ url, data: { form_ids: this.selectedFormIds } });
        this.conditionSetStore.refableQings = qings;
      } catch (error) {
        console.error('Failed to updateRefableQings:', error);
      } finally {
        ELMO.app.loading(false);
      }
    };

  @action
    handleSelectForm = (event) => {
      this.selectedFormIds = [event.target.value];
    };

  @action
    handleSelectSubmitterForType = (type) => (event) => {
      const { id, text: name } = event.params.data;
      this.selectedSubmittersForType[type] = [{ id, name }];
    };

  @action
    handleChangeAdvancedSearch = (event) => {
      this.advancedSearchText = event.target.value;
    };

  @action
    handleDateChange = ({ startDate, endDate }) => {
      this.startDate = startDate;
      this.endDate = endDate;
    };
}

export default FiltersModel;
