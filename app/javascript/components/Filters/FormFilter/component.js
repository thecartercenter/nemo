import React from 'react';
import PropTypes from 'prop-types';
import Select2 from 'react-select2-wrapper/lib/components/Select2.full';
import { inject, observer } from 'mobx-react';

import 'react-select2-wrapper/css/select2.css';
import { getItemNameFromId, parseListForSelect2 } from '../utils';
import FilterOverlayTrigger from '../FilterOverlayTrigger/component';

@inject('filtersStore')
@observer
class FormFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
    onSubmit: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);
    this.select2 = React.createRef();
  }

  handleClearSelection = () => {
    const { filtersStore } = this.props;
    filtersStore.selectedFormIds = [];

    /*
     * Select2 doesn't make this easy... wait for state update then close the dropdown.
     * https://select2.org/programmatic-control/methods#closing-the-dropdown
     */
    setTimeout(() => this.select2.current.el.select2('close'), 1);
  };

  renderPopover = () => {
    const { filtersStore } = this.props;
    const { allForms, selectedFormId, handleSelectForm } = filtersStore;

    return (
      <Select2
        data={parseListForSelect2(allForms)}
        onSelect={handleSelectForm}
        onUnselect={this.handleClearSelection}
        options={{
          allowClear: true,
          placeholder: I18n.t('filter.choose_form'),
          dropdownCssClass: 'filters-select2-dropdown',
          width: '100%',
        }}
        ref={this.select2}
        value={selectedFormId}
      />
    );
  };

  render() {
    const { filtersStore, onSubmit } = this.props;
    const { allForms, original: { selectedFormIds } } = filtersStore;
    const originalFormNames = selectedFormIds.map((id) => getItemNameFromId(allForms, id));

    return (
      <FilterOverlayTrigger
        id="form-filter"
        title={I18n.t('filter.form')}
        popoverContent={this.renderPopover()}
        onSubmit={onSubmit}
        hints={originalFormNames}
      />
    );
  }
}

export default FormFilter;
