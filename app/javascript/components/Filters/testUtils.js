import FiltersModel from './model';
import ConditionSetModel from '../ConditionSetFormField/model';
import { submitterType } from './SubmitterFilter/component';

export const getFiltersStore = () => new FiltersModel({
  conditionSetStore: new ConditionSetModel({
    conditions: [
      {
        leftQingId: '1',
        op: 'eq',
        operatorOptions: [
          { name: '= equals', id: 'eq' },
          { name: '≠ does not equal', id: 'neq' },
        ],
        value: '5',
      },
    ],

    refableQings: [
      {
        id: '1',
        code: 'One',
        fullDottedRank: '1',
        rank: 1,
      },
      {
        id: '2',
        code: 'Two',
        fullDottedRank: '2',
        rank: 2,
      },
    ],
  }),

  allForms: [
    { id: '1', name: 'One' },
    { id: '2', name: 'Two' },
    { id: '3', name: "Q\"uo'te`s" },
  ],

  originalFormIds: [
    '1',
  ],

  selectedFormIds: [
    '2',
  ],

  originalIsReviewed: null,

  isReviewed: true,

  allSubmittersForType: {
    [submitterType.USER]: [
      { id: 'A', name: 'User A' },
      { id: 'B', name: 'User B' },
    ],
    [submitterType.GROUP]: [
      { id: 'A', name: 'Group A' },
      { id: 'B', name: 'Group B' },
    ],
  },

  originalSubmittersForType: {
    [submitterType.USER]: [{ id: 'A', name: 'User A' }],
    [submitterType.GROUP]: [],
  },

  selectedSubmittersForType: {
    [submitterType.USER]: [{ id: 'B', name: 'User B' }],
    [submitterType.GROUP]: [{ id: 'B', name: 'Group B' }],
  },

  advancedSearchText: 'query',
});
