import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import Form from 'react-bootstrap/Form';
import ButtonGroup from 'react-bootstrap/ButtonGroup';
import { inject, observer } from 'mobx-react';

import { getButtonHintString } from './utils';

const CHOICES = [
  { name: I18n.t('common._yes'), value: true },
  { name: I18n.t('common._no'), value: false },
  { name: I18n.t('common.either'), value: null },
];

@inject('filtersStore')
@observer
class FormFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
    onSubmit: PropTypes.func.isRequired,
  };

  handleChangeIsReviewed = (value) => {
    const { filtersStore } = this.props;
    filtersStore.isReviewed = value;
  }

  renderPopover = () => {
    const { filtersStore, onSubmit } = this.props;
    const { isReviewed } = filtersStore;

    return (
      <Popover
        className="filters-popover"
        id="reviewed-filter"
      >
        <div>
          <Form.Label>{I18n.t('filter.is_reviewed')}</Form.Label>
        </div>
        <ButtonGroup>
          {CHOICES.map(({ name, value }) => (
            <Button
              key={name}
              variant="secondary"
              active={isReviewed === value}
              onClick={() => this.handleChangeIsReviewed(value)}
            >
              {name}
            </Button>
          ))}
        </ButtonGroup>

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
    const { originalIsReviewed } = filtersStore;
    const hints = originalIsReviewed == null
      ? null
      : originalIsReviewed ? [I18n.t('common._yes')] : [I18n.t('common._no')];

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
