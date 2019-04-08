import { action, observable } from 'mobx';

class FiltersModel {
  @observable
  selectedFormIds = [];

  @observable
  advancedSearchText = '';

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
