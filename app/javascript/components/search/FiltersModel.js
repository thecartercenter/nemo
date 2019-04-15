import isEmpty from 'lodash/isEmpty';
import { action, observable, computed, reaction, toJS } from 'mobx';

import ConditionSetModel from '../ConditionSetModel/ConditionSetModel';
import { SUBMITTER_TYPES } from './SubmitterFilter';

/** Empty model to be used for resetting the store as needed. */
const initialConditionSetData = Object.freeze(toJS(new ConditionSetModel({
  namePrefix: 'questioning[display_conditions_attributes]',
  conditionableType: 'FormItem',
  hide: false,
})));

/** Map from each type to an empty array. */
const getEmptySubmitterTypeMap = () => SUBMITTER_TYPES.reduce((reduction, type) => {
  // eslint-disable-next-line no-param-reassign
  reduction[type] = [];
  return reduction;
}, {});

class FiltersModel {
  @observable
  conditionSetStore = new ConditionSetModel(initialConditionSetData);

  @observable
  allForms = [];

  @observable
  originalFormIds = [];

  @observable
  selectedFormIds = [];

  @observable
  originalIsReviewed = null;

  @observable
  isReviewed = null;

  @observable
  allSubmittersForType = getEmptySubmitterTypeMap();

  @observable
  selectedSubmitterIdsForType = getEmptySubmitterTypeMap();

  @observable
  advancedSearchText = '';

  @computed
  get selectedFormId() {
    return isEmpty(this.selectedFormIds) ? '' : this.selectedFormIds[0];
  }

  constructor(initialValues) {
    Object.assign(this, initialValues);

    // Update conditionSet IDs when selected forms change.
    reaction(
      () => this.selectedFormId,
      async (selectedFormId) => {
        if (this.conditionSetStore.formId !== selectedFormId) {
          // Reset the entire store because the available questions will have changed.
          Object.assign(this.conditionSetStore, new ConditionSetModel(initialConditionSetData), {});

          await this.updateRefableQings();
        }
      },
    );
  }

  @action
  updateRefableQings = async () => {
    ELMO.app.loading(true);
    const url = this.buildUrl();
    try {
      if (process.env.NODE_ENV === 'test') return;

      const { refableQings } = await $.ajax(url);
      this.conditionSetStore.refableQings = refableQings;
    } catch (error) {
      console.error('Failed to updateRefableQings:', error);
    } finally {
      ELMO.app.loading(false);
    }
  }

  buildUrl = () => {
    return ELMO.app.url_builder.build('form-items', 'condition-form');
  }

  @action
  handleSelectForm = (event) => {
    this.selectedFormIds = [event.target.value];
  }

  @action
  handleSelectSubmitterForType = (type) => (event) => {
    this.selectedSubmitterIdsForType[type] = [event.target.value];
  }

  @action
  handleChangeAdvancedSearch = (event) => {
    this.advancedSearchText = event.target.value;
  }
}

export default FiltersModel;
