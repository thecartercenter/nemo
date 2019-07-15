import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';

import { getButtonHintString } from '../utils';
import FilterPopover from '../FilterPopover/component';

class FilterOverlayTrigger extends React.Component {
  static propTypes = {
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
    const { onSubmit } = this.props;
    // TODO: Don't search if nothing was modified.
    onSubmit();
  }

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
  }

  render() {
    const { id, title, hints, buttonClass } = this.props;

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
        <Button id={id} variant="secondary" className={buttonClass}>
          {title + getButtonHintString(hints)}
        </Button>
      </OverlayTrigger>
    );
  }
}

export default FilterOverlayTrigger;
