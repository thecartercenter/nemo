import React from 'react';
import { shallow } from 'enzyme';

import ConditionSetModel from '../model';
import Component from './component';

let defaultProps;

beforeEach(() => {
  defaultProps = {
    conditionSetStore: new ConditionSetModel({
      namePrefix: 'questioning[display_conditions_attributes]',
      refableQings: [
        {
          id: '1',
          code: 'One',
          fullDottedRank: '1',
          rank: 1,
          qtypeName: 'integer',
          textual: false,
          numeric: true,
        }, {
          id: '2',
          code: 'Two',
          fullDottedRank: '2',
          rank: 2,
          qtypeName: 'text',
          textual: true,
          numeric: false,
        },
      ],
    }),
    condition: {
      leftQingId: '1',
      op: 'eq',
      operatorOptions: [
        { name: '= equals', id: 'eq' },
        { name: '≠ does not equal', id: 'neq' },
      ],
      refableQings: [],
      rightQingOptions: [],
    },
    index: 5,
  };
});

describe('with rightSideType as literal', () => {
  beforeEach(() => {
    defaultProps.condition.rightSideType = 'literal';
  });

  describe('with non-select leftQing', () => {
    beforeEach(() => {
      defaultProps.condition.value = '123';
    });

    it('sends correct props to ConditionValueField', () => {
      const wrapper = shallow(<Component {...defaultProps} />);
      expect(wrapper).toMatchSnapshot();
    });
  });

  describe('with select leftQing', () => {
    beforeEach(() => {
      defaultProps.condition.optionSetId = '1a2';
      defaultProps.condition.optionNodeId = '7b5';
    });

    it('sends correct props to ConditionValueField', () => {
      const wrapper = shallow(<Component {...defaultProps} />);
      expect(wrapper).toMatchSnapshot();
    });
  });
});

describe('with rightSideType as qing', () => {
  beforeEach(() => {
    defaultProps.condition.rightSideType = 'qing';
  });

  describe('with no applicable rightQingOptions', () => {
    beforeEach(() => {
      defaultProps.condition.rightQingId = '2';
    });

    it('renders no rightQingType dropdown', () => {
      const wrapper = shallow(<Component {...defaultProps} />);
      expect(wrapper).toMatchSnapshot();
    });
  });

  describe('with applicable rightQingOptions', () => {
    beforeEach(() => {
      defaultProps.condition.rightQingOptions = [{
        id: '3',
        code: 'Three',
        fullDottedRank: '3',
        rank: 3,
        qtypeName: 'integer',
        textual: false,
        numeric: true,
      }];
      defaultProps.condition.leftQingId = '3';
    });

    describe('with forceRightSideLiteral true', () => {
      beforeEach(() => {
        defaultProps.conditionSetStore.forceRightSideLiteral = true;
      });

      it('renders no rightQingType dropdown', () => {
        const wrapper = shallow(<Component {...defaultProps} />);
        expect(wrapper).toMatchSnapshot();
      });
    });

    describe('with forceRightSideLiteral false', () => {
      it('renders rightQingType dropdown and rightQing dropdown', () => {
        const wrapper = shallow(<Component {...defaultProps} />);
        expect(wrapper).toMatchSnapshot();
      });
    });
  });
});
