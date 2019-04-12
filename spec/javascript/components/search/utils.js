import FiltersModel from '../../../../app/javascript/components/search/FiltersModel';
import ConditionSetModel from '../../../../app/javascript/components/ConditionSetModel/ConditionSetModel';

export const filtersStore = new FiltersModel({
  conditionSetStore: new ConditionSetModel({
    conditions: [
      {
        refQingId: '1',
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
    {
      id: '1',
      name: 'One',
    },
    {
      id: '2',
      name: 'Two',
    },
    {
      id: '3',
      name: "Q\"uo'te`s",
    },
  ],

  originalFormIds: [
    '1',
  ],

  selectedFormIds: [
    '2',
  ],

  advancedSearchText: 'query',
});
