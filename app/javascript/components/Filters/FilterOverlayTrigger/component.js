import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import { inject, observer } from 'mobx-react';

import { getButtonHintString } from '../utils';
import FilterPopover from '../FilterPopover/component';

@inject('filtersStore')
@observer
class FilterOverlayTrigger extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object.isRequired,
    id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    popoverContent: PropTypes.node.isRequired,
    popoverClass: PropTypes.string,
    buttonsContainerClass: PropTypes.string,
    onSubmit: PropTypes.func.isRequired,
    hints: PropTypes.arrayOf(PropTypes.string),
    buttonClass: PropTypes.string,
  };

  handleExit = () => {
    const { filtersStore, onSubmit } = this.props;
    if (filtersStore.isDirty) {
      onSubmit();
    }
  };

  renderPopover = () => {
    const { id, popoverContent, popoverClass, buttonsContainerClass, onSubmit } = this.props;

    return (
      <FilterPopover
        id={id}
        onSubmit={onSubmit}
        className={popoverClass}
        buttonsContainerClass={buttonsContainerClass}
      >
        {popoverContent}
      </FilterPopover>
    );
  };

  render() {
    const { id, title, hints, buttonClass } = this.props;
    const hintString = getButtonHintString(hints);
    const active = Boolean(hintString);

    return (
      <OverlayTrigger
        id={id}
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        onExit={this.handleExit}
        trigger="click"
      >
        <Button
          id={id}
          variant="secondary"
          className={[buttonClass, active ? 'active-filter' : null]}
        >
          {title + hintString}
          <i className="fa fa-chevron-down inline" />
        </Button>
      </OverlayTrigger>
    );
  }
}

export default FilterOverlayTrigger;
