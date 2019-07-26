import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Form from 'react-bootstrap/Form';
import ButtonGroup from 'react-bootstrap/ButtonGroup';
import { inject, observer } from 'mobx-react';

import FilterOverlayTrigger from '../FilterOverlayTrigger/component';

const CHOICES = [
  { name: I18n.t('common._yes'), value: true, id: 'yes', variant: 'success' },
  { name: I18n.t('common._no'), value: false, id: 'no', variant: 'danger' },
  { name: I18n.t('common.either'), value: null, id: 'either', variant: 'secondary' },
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
    const { filtersStore } = this.props;
    const { isReviewed } = filtersStore;

    return (
      <React.Fragment>
        <div>
          <Form.Label>{I18n.t('filter.is_reviewed')}</Form.Label>
        </div>
        <ButtonGroup>
          {CHOICES.map(({ name, value, id, variant }) => (
            <Button
              key={id}
              id={id}
              variant={variant}
              active={isReviewed === value}
              onClick={() => this.handleChangeIsReviewed(value)}
            >
              {name}
            </Button>
          ))}
        </ButtonGroup>
      </React.Fragment>
    );
  }

  render() {
    const { filtersStore, onSubmit } = this.props;
    const { original: { isReviewed } } = filtersStore;
    const hints = isReviewed == null
      ? null
      : isReviewed ? [I18n.t('common._yes')] : [I18n.t('common._no')];

    return (
      <FilterOverlayTrigger
        id="reviewed-filter"
        title={I18n.t('filter.reviewed')}
        popoverContent={this.renderPopover()}
        onSubmit={onSubmit}
        hints={hints}
        buttonClass="btn-margin-left"
      />
    );
  }
}

export default FormFilter;
