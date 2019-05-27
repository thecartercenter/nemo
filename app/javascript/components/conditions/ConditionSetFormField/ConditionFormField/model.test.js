import ConditionModel from './model';

it('computes currTextValue (basic value)', () => {
  const store = new ConditionModel({ value: 'foo' });
  expect(store.currTextValue).toMatchSnapshot();
});

it('computes currTextValue (cascading select with nothing selected)', () => {
  const store = new ConditionModel({ value: 'unused', optionSetId: 'something' });
  expect(store.currTextValue).toMatchSnapshot();
});

it('computes currTextValue (cascading select with something selected)', () => {
  const store = new ConditionModel({
    optionSetId: 'something',
    levels: [
      {
        selected: '1',
        options: [
          { id: '1', name: 'One' },
        ],
      },
    ],
  });
  expect(store.currTextValue).toMatchSnapshot();
});
