import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import Form from 'react-bootstrap/Form';
import ButtonGroup from 'react-bootstrap/ButtonGroup';
import { inject, observer } from 'mobx-react';

import { getButtonHintString } from '../utils';
import FilterPopover from '../FilterPopover/component';

const CHOICES = [
  { name: I18n.t('common._yes'), value: true, id: 'yes' },
  { name: I18n.t('common._no'), value: false, id: 'no' },
  { name: I18n.t('common.either'), value: null, id: 'either' },
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
      <FilterPopover
        id="reviewed-filter"
        onSubmit={onSubmit}
      >
        <div>
          <Form.Label>{I18n.t('filter.is_reviewed')}</Form.Label>
        </div>
        <ButtonGroup>
          {CHOICES.map(({ name, value, id }) => (
            <Button
              key={id}
              id={id}
              variant="secondary"
              active={isReviewed === value}
              onClick={() => this.handleChangeIsReviewed(value)}
            >
              {name}
            </Button>
          ))}
        </ButtonGroup>
      </FilterPopover>
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
        <Button id="reviewed-filter" variant="secondary" className="btn-margin-left">
          {I18n.t('filter.reviewed') + getButtonHintString(hints)}
        </Button>
      </OverlayTrigger>
    );
  }
}

export default FormFilter;
