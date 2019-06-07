import React from 'react';
import PropTypes from 'prop-types';
import Popover from 'react-bootstrap/Popover';
import FilterPopoverButtons from './FilterPopoverButtons/component';

class FilterPopover extends React.Component {
  static propTypes = {
    children: PropTypes.node.isRequired,
    onSubmit: PropTypes.func.isRequired,
    className: PropTypes.string,
    buttonsContainerClass: PropTypes.string,
  };

  render() {
    const { children, className, onSubmit, buttonsContainerClass, ...popoverProps } = this.props;

    return (
      <Popover
        {...popoverProps}
        className={`filters-popover ${className || ''}`.trim()}
      >
        {children}

        <FilterPopoverButtons
          containerClass={buttonsContainerClass}
          onSubmit={onSubmit}
        />
      </Popover>
    );
  }
}

export default FilterPopover;
