import flatten from 'lodash/flatten';
import React from 'react';
import PropTypes from 'prop-types';
import Select2 from 'react-select2-wrapper/lib/components/Select2.full';
import { inject, observer } from 'mobx-react';

import 'react-select2-wrapper/css/select2.css';
import FilterPopover from '../FilterPopover/component';
import FilterOverlayTrigger from '../FilterOverlayTrigger/component';

// Note: These string values are hard-coded as i18n keys, and are also used for search string keywords.
export const submitterType = {
  USER: 'submitter',
  GROUP: 'group',
};
export const SUBMITTER_TYPES = Object.values(submitterType);

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
  }

  renderPopover = () => {
    const { filtersStore, onSubmit } = this.props;
    const { selectedSubmittersForType, handleSelectSubmitterForType } = filtersStore;

    return (
      <FilterPopover
        className="popover-multi-select2"
        id="submitter-filter"
        onSubmit={onSubmit}
      >
        {SUBMITTER_TYPES.map((type) => {
          const { dataUrl, resultsKey } = select2Config[type];

          return (
            <Select2
              key={type}
              id={type}
              onSelect={handleSelectSubmitterForType(type)}
              onUnselect={this.handleClearSelection(type)}
              options={{
                allowClear: true,
                placeholder: I18n.t(`filter.choose_submitter.${type}`),
                dropdownCssClass: 'filters-select2-dropdown',
                width: '100%',
                ajax: ELMO.select2.getAjaxParams(dataUrl, resultsKey),
              }}
              ref={this.select2[type]}
              value={selectedSubmittersForType[type].map(({ id }) => id)}
            />
          );
        })}
      </FilterPopover>
    );
  }

  render() {
    const { filtersStore } = this.props;
    const { originalSubmittersForType } = filtersStore;
    const submitterNames = flatten(SUBMITTER_TYPES.map((type) => {
      return originalSubmittersForType[type].map(({ name }) => name);
    }));

    return (
      <FilterOverlayTrigger
        id="submitter-filter"
        title={I18n.t('filter.submitter')}
        overlay={this.renderPopover()}
        hints={submitterNames}
        buttonClass="btn-margin-left"
      />
    );
  }
}

export default SubmitterFilter;
