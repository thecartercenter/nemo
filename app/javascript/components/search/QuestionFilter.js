import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';

import { getButtonHintString } from './utils';

class QuestionFilter extends React.Component {
  renderPopover = () => {
    const { onSubmit } = this.props;

    return (
      <Popover
        className="filters-popover"
        id="form-filter"
      >

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
    return (
      <OverlayTrigger
        id="question-filter"
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        trigger="click"
      >
        <Button id="question-filter" className="btn-secondary btn-margin-left">
          {I18n.t('filter.question') + getButtonHintString([])}
        </Button>
      </OverlayTrigger>
    );
  }
}

QuestionFilter.propTypes = {
  onSubmit: PropTypes.func.isRequired,
};

export default QuestionFilter;
