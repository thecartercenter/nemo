import { getLevelsValues, applyDefaultLevelsValues } from '../../../../app/javascript/components/ConditionSetModel/utils';

it('gets levels values', () => {
  const result = getLevelsValues([
    { name: 'foo', selected: 'bar' },
    { name: 'baz', selected: 'qux' },
  ]);
  expect(result).toMatchSnapshot();
});

it('applies default levels values', () => {
  const result = applyDefaultLevelsValues([
    { name: 'foo', selected: 'bar' },
    { name: 'baz', selected: null },
  ], {
    baz: 'qux',
  });
  expect(result).toMatchSnapshot();
});
