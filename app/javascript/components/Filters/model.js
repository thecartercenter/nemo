import isEmpty from 'lodash/isEmpty';
import cloneDeep from 'lodash/cloneDeep';
import { action, observable, computed, reaction, toJS } from 'mobx';

import ConditionSetModel from '../conditions/ConditionSetFormField/model';
import { SUBMITTER_TYPES } from './SubmitterFilter/component';

/** Empty model to be used for resetting the store as needed. */
const initialConditionSetData = Object.freeze(toJS(new ConditionSetModel({
  namePrefix: 'questioning[display_conditions_attributes]',
  conditionableType: 'FormItem',
  hide: false,
  forceEqualsOp: true,
  forceRightSideLiteral: true,
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
  original = new Map();

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

  @computed
  get selectedFormId() {
    return isEmpty(this.selectedFormIds) ? '' : this.selectedFormIds[0];
  }

  constructor(initialValues = {}) {
    this.initialize(initialValues);

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

  // Initial values may not be known at the time the store is created.
  // This method can be used to set the initial values at a later point.
  @action
  initialize = (initialValues) => {
    Object.assign(this, initialValues);

    Object.assign(this.original, {
      selectedFormIds: cloneDeep(initialValues.selectedFormIds) || [],
      isReviewed: initialValues.isReviewed || null,
      selectedSubmittersForType: cloneDeep(initialValues.selectedSubmittersForType) || getEmptySubmitterTypeMap(),
    });
  }

  @action
  updateRefableQings = async () => {
    ELMO.app.loading(true);
    const url = ELMO.app.url_builder.build('filter-data', 'qings');
    try {
      if (process.env.NODE_ENV === 'test') return;
      let qings = await $.ajax({url: url, data: {form_ids: this.selectedFormIds}});
      this.conditionSetStore.refableQings = qings;
    } catch (error) {
      console.error('Failed to updateRefableQings:', error);
    } finally {
      ELMO.app.loading(false);
    }
  }

  @action
  handleSelectForm = (event) => {
    this.selectedFormIds = [event.target.value];
  }

  @action
  handleSelectSubmitterForType = (type) => (event) => {
    const { id, text: name } = event.params.data;
    this.selectedSubmittersForType[type] = [{ id, name }];
  }

  @action
  handleChangeAdvancedSearch = (event) => {
    this.advancedSearchText = event.target.value;
  }
}

export default FiltersModel;
