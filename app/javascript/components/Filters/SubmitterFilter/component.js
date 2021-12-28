import flatten from 'lodash/flatten';
import React from 'react';
import PropTypes from 'prop-types';
import Select2 from 'react-select2-wrapper/lib/components/Select2.full';
import { inject, observer } from 'mobx-react';

import 'react-select2-wrapper/css/select2.css';

import { parseListForSelect2 } from '../utils';
import { submitterType, SUBMITTER_TYPES } from './utils';
import FilterOverlayTrigger from '../FilterOverlayTrigger/component';

const select2Config = {
  [submitterType.USER]: {
    dataUrl: ELMO.app.url_builder.build('responses', 'possible-submitters'),
    resultsKey: 'possible_users',
  },
  [submitterType.GROUP]: {
    dataUrl: ELMO.app.url_builder.build('user_groups', 'possible-groups'),
    resultsKey: 'possible_groups',
  },
};

@inject('filtersStore')
@observer
class SubmitterFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
    onSubmit: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);

    // Create refs for each select.
    this.select2 = {};
    SUBMITTER_TYPES.forEach((type) => {
      this.select2[type] = React.createRef();
    });
  }

  handleClearSelection = (type) => () => {
    const { filtersStore } = this.props;
    filtersStore.selectedSubmittersForType[type] = [];

    /*
     * Select2 doesn't make this easy... wait for state update then close the dropdown.
     * https://select2.org/programmatic-control/methods#closing-the-dropdown
     */
    setTimeout(() => this.select2[type].current.el.select2('close'), 1);
  };

  renderPopover = () => {
    const { filtersStore } = this.props;
    const { selectedSubmittersForType, handleSelectSubmitterForType } = filtersStore;

    return (
      <>
        {SUBMITTER_TYPES.map((type) => {
          const { dataUrl, resultsKey } = select2Config[type];

          return (
            <Select2
              key={type}
              id={type}
              data={parseListForSelect2(selectedSubmittersForType[type])}
              onSelect={handleSelectSubmitterForType(type)}
              onUnselect={this.handleClearSelection(type)}
              options={{
                allowClear: true,
                placeholder: I18n.t(`filter.choose_submitter.${type}`),
                dropdownCssClass: 'filters-select2-dropdown',
                width: '100%',
                ajax: (new ELMO.Utils.Select2OptionBuilder()).ajax(dataUrl, resultsKey, 'name'),
              }}
              ref={this.select2[type]}
              value={selectedSubmittersForType[type].map(({ id }) => id)[0]}
            />
          );
        })}
      </>
    );
  };

  render() {
    const { filtersStore, onSubmit } = this.props;
    const { original: { selectedSubmittersForType } } = filtersStore;
    const submitterNames = flatten(SUBMITTER_TYPES.map((type) => {
      return selectedSubmittersForType[type].map(({ name }) => name);
    }));

    return (
      <FilterOverlayTrigger
        id="submitter-filter"
        title={I18n.t('filter.submitter')}
        popoverContent={this.renderPopover()}
        popoverClass="popover-multi-select2"
        onSubmit={onSubmit}
        hints={submitterNames}
        buttonClass="btn-margin-left"
      />
    );
  }
}

export default SubmitterFilter;
