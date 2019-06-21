import FiltersModel from './model';
import ConditionSetModel from '../conditions/ConditionSetFormField/model';
import { submitterType } from './SubmitterFilter/utils';

export function getFiltersStore() {
  const model = new FiltersModel({
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

    selectedFormIds: [
      '2',
    ],

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

    selectedSubmittersForType: {
      [submitterType.USER]: [{ id: 'B', name: 'User B' }],
      [submitterType.GROUP]: [{ id: 'B', name: 'Group B' }],
    },

    advancedSearchText: 'query',
  });

  model.original.selectedFormIds = [
    '1',
  ];

  model.original.isReviewed = null;

  model.original.selectedSubmittersForType = {
    [submitterType.USER]: [{ id: 'A', name: 'User A' }],
    [submitterType.GROUP]: [],
  };

  return model;
}
