import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';

import { getButtonHintString } from '../utils';

class FilterOverlayTrigger extends React.Component {
  static propTypes = {
    id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    overlay: PropTypes.node.isRequired,
    hints: PropTypes.arrayOf(PropTypes.string),
    buttonClass: PropTypes.string,
  };

  render() {
    const { id, title, overlay, hints, buttonClass } = this.props;

    return (
      <OverlayTrigger
        id={id}
        containerPadding={25}
        overlay={overlay}
        placement="bottom"
        rootClose
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
