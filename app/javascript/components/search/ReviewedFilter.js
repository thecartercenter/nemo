import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import Form from 'react-bootstrap/Form';
import { inject, observer } from 'mobx-react';

import { getButtonHintString } from './utils';

@inject('filtersStore')
@observer
class FormFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
    onSubmit: PropTypes.func.isRequired,
  };

  handleClearReviewed = () => {
    const { filtersStore, onSubmit } = this.props;

    filtersStore.isReviewed = null;
    onSubmit();
  }

  renderPopover = () => {
    const { filtersStore, onSubmit } = this.props;
    const { isReviewed, handleChangeIsReviewed } = filtersStore;

    return (
      <Popover
        className="filters-popover"
        id="reviewed-filter"
      >
        {/* Note: `id` is required for checkbox label to be clickable. */}
        <Form.Check
          id="is-reviewed"
          type="checkbox"
          label={I18n.t('filter.is_reviewed')}
          checked={isReviewed || ''}
          onChange={handleChangeIsReviewed}
        />

        <div className="btn-apply-container">
          <Button
            className="btn-clear btn-secondary"
            onClick={this.handleClearReviewed}
          >
            {I18n.t('common.clear')}
          </Button>
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
    const { isReviewed } = filtersStore;
    const hints = isReviewed == null
      ? null
      : isReviewed ? [I18n.t('common._yes')] : [I18n.t('common._no')];

    return (
      <OverlayTrigger
        id="reviewed-filter"
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        trigger="click"
      >
        <Button id="reviewed-filter" className="btn-secondary btn-margin-left">
          {I18n.t('filter.reviewed') + getButtonHintString(hints)}
        </Button>
      </OverlayTrigger>
    );
  }
}

export default FormFilter;
