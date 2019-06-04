import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';

class FilterPopoverButtons extends React.Component {
  static propTypes = {
    onSubmit: PropTypes.func.isRequired,
    containerClass: PropTypes.string,
  };

  render() {
    const { onSubmit, containerClass } = this.props;

    return (
      <div className={`btn-apply-container ${containerClass || ''}`.trim()}>
        <Button
          className="btn-apply"
          onClick={onSubmit}
        >
          {I18n.t('common.apply')}
        </Button>
      </div>
    );
  }
}

export default FilterPopoverButtons;
