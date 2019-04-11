import { action, observable, reaction } from 'mobx';

import ConditionSetModel from '../ConditionSetModel/ConditionSetModel';

class FiltersModel {
  conditionSetStore = new ConditionSetModel();

  @observable
  allForms = [];

  @observable
  originalFormIds = [];

  @observable
  selectedFormIds = [];

  @observable
  advancedSearchText = '';

  constructor() {
    // Update conditionSet IDs when selected forms change.
    reaction(
      () => this.selectedFormIds,
      (selectedFormIds) => {
        const selectedFormId = selectedFormIds[0] || '';
        this.conditionSetStore.conditionableId = selectedFormId;
        this.conditionSetStore.formId = selectedFormId;
      },
    );
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
