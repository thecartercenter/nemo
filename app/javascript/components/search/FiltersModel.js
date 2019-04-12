import isEmpty from 'lodash/isEmpty';
import queryString from 'query-string';
import { action, observable, computed, reaction, toJS } from 'mobx';

import ConditionSetModel from '../ConditionSetModel/ConditionSetModel';

// Empty model to be used for resetting the store as needed.
const initialConditionSetData = Object.freeze(toJS(new ConditionSetModel({
  namePrefix: 'questioning[display_conditions_attributes]',
  conditionableType: 'FormItem',
  hide: false,
})));

class FiltersModel {
  conditionSetStore = new ConditionSetModel(initialConditionSetData);

  @observable
  allForms = [];

  @observable
  originalFormIds = [];

  @observable
  selectedFormIds = [];

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
          Object.assign(this.conditionSetStore, new ConditionSetModel(initialConditionSetData), {
            conditionableId: selectedFormId,
            formId: selectedFormId,
          });

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
      const { refableQings } = await $.ajax(url);
      this.conditionSetStore.refableQings = refableQings;
    } catch (error) {
      console.error('Failed to updateRefableQings:', error);
    } finally {
      ELMO.app.loading(false);
    }
  }

  buildUrl = () => {
    const formId = this.selectedFormId;
    const params = {
      conditionable_id: formId || undefined,
      conditionable_type: formId ? 'FormItem' : undefined,
    };
    const url = ELMO.app.url_builder.build('form-items', 'condition-form');
    return `${url}?${queryString.stringify(params)}`;
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
}

export default FiltersModel;
