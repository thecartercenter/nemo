import React from 'react';
import PropTypes from 'prop-types';
import Popover from 'react-bootstrap/Popover';

class FilterPopover extends React.Component {
  static propTypes = {
    children: PropTypes.node.isRequired,
    className: PropTypes.string,
  };

  render() {
    const { children, className, ...props } = this.props;

    return (
      <Popover
        {...props}
        className={`filters-popover ${className || ''}`.trim()}
      >
        {children}
      </Popover>
    );
  }
}

export default FilterPopover;
