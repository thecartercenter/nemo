import flatten from 'lodash/flatten';
import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import Select2 from 'react-select2-wrapper/lib/components/Select2.full';
import { inject, observer } from 'mobx-react';

import 'react-select2-wrapper/css/select2.css';
import { getButtonHintString } from '../utils';

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
      <Popover
        className="filters-popover popover-multi-select2"
        id="submitter-filter"
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

        <div className="btn-apply-container">
          <Button
            className="btn-apply"
            onClick={onSubmit}
          >
            {I18n.t('common.apply')}
          </Button>
        </div>
      </Popover>
    );
  }

  render() {
    const { filtersStore } = this.props;
    const { originalSubmittersForType } = filtersStore;
    const submitterNames = flatten(SUBMITTER_TYPES.map((type) => {
      return originalSubmittersForType[type].map(({ name }) => name);
    }));

    return (
      <OverlayTrigger
        id="submitter-filter"
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        trigger="click"
      >
        <Button id="submitter-filter" variant="secondary" className="btn-margin-left">
          {I18n.t('filter.submitter') + getButtonHintString(submitterNames)}
        </Button>
      </OverlayTrigger>
    );
  }
}

export default SubmitterFilter;
