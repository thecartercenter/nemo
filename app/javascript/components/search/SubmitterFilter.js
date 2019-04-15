import flatten from 'lodash/flatten';
import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import Select2 from 'react-select2-wrapper/lib/components/Select2.full';
import { inject, observer } from 'mobx-react';

import 'react-select2-wrapper/css/select2.css';
import { getButtonHintString, getItemNameFromId, parseListForSelect2 } from './utils';

// Note: These string values are hard-coded as i18n keys, and are also used for search string keywords.
export const submitterType = {
  USER: 'submitter',
  GROUP: 'group',
};
export const SUBMITTER_TYPES = Object.values(submitterType);

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
    filtersStore.selectedSubmitterIdsForType[type] = [];

    /*
     * Select2 doesn't make this easy... wait for state update then close the dropdown.
     * https://select2.org/programmatic-control/methods#closing-the-dropdown
     */
    setTimeout(() => this.select2[type].current.el.select2('close'), 1);
  }

  renderPopover = () => {
    const { filtersStore, onSubmit } = this.props;
    const { allSubmittersForType, selectedSubmitterIdsForType, handleSelectSubmitterForType } = filtersStore;

    return (
      <Popover
        className="filters-popover popover-multi-select2"
        id="submitter-filter"
      >
        {SUBMITTER_TYPES.map((type) => (
          <Select2
            key={type}
            id={type}
            data={parseListForSelect2(allSubmittersForType[type])}
            onSelect={handleSelectSubmitterForType(type)}
            onUnselect={this.handleClearSelection(type)}
            options={{
              allowClear: true,
              placeholder: I18n.t(`filter.choose_submitter.${type}`),
              dropdownCssClass: 'filters-select2-dropdown',
              width: '100%',
            }}
            ref={this.select2[type]}
            value={selectedSubmitterIdsForType[type]}
          />
        ))}

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
    const { allSubmittersForType, selectedSubmitterIdsForType } = filtersStore;
    const submitterNames = flatten(SUBMITTER_TYPES.map((type) => {
      return selectedSubmitterIdsForType[type].map((id) => getItemNameFromId(allSubmittersForType[type], id));
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
        <Button id="submitter-filter" className="btn-secondary btn-margin-left">
          {I18n.t('filter.submitter') + getButtonHintString(submitterNames)}
        </Button>
      </OverlayTrigger>
    );
  }
}

export default SubmitterFilter;
