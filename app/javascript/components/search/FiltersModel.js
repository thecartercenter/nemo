import isEmpty from 'lodash/isEmpty';
import { action, observable, computed, reaction, toJS } from 'mobx';

import ConditionSetModel from '../ConditionSetModel/ConditionSetModel';

// Empty model to be used for resetting the store as needed.
const initialConditionSetData = Object.freeze(toJS(new ConditionSetModel({
  namePrefix: 'questioning[display_conditions_attributes]',
  conditionableType: 'FormItem',
  hide: false,
})));

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
  handleClearFormSelection = () => {
    this.selectedFormIds = [];
  }

  @action
  handleChangeAdvancedSearch = (event) => {
    this.advancedSearchText = event.target.value;
  }

  @action
  handleChangeIsReviewed = (event) => {
    this.isReviewed = event.target.checked;
  }
}

export default FiltersModel;
