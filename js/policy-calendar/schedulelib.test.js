import * as lib from './schedulelib'

const dayWeightsZero = lib.initDayWeights()

test('initDayWeights produces the expected 40 x 4, zero filled 2-dim array structure', () => {
  const dayWeights = lib.initDayWeights()
  expect(dayWeights.length).toBe(40)
  // use 'for' rather than 'dayWeights.forEach' as the latter will silenly skip "unitialized" items and can thus report
  // a false positive as to the expected structure
  for (let i = 0; i < dayWeights.length; i += 1) {
    const week = dayWeights[i]
    expect(week.length).toBe(4)
    for (let j = 0; j < week.lenght; j += 1) expect(week[j]).toBe(0)
  }
})

describe('combineMonthsWeight', () => {
  const dayWeights = lib.initDayWeights()
  dayWeights[0][3] = 1 // week 0, month 0, day 3 (Thurs); total 1
  dayWeights[4][1] = 1 // week 4, month 2; total 2
  dayWeights[4][2] = 1
  dayWeights[10][0] = 3 // week 10, month 3; total 3

  test.each([[[0], 1], [[1], 2], [[2], 3]])
    ('correctly sums monthly-weights for single month %d to %d', (monthsSet, expectedWeight) => {
      const weight = lib.combineMonthsWeight(dayWeights, monthsSet)
      expect(weight).toBe(expectedWeight)
    })
})


describe('leastMonthsSet', () => {
  test('selects first month set when all equal; single sets',
    () => expect(lib.leastMonthsSet(dayWeightsZero, [[0],[1],[2]])).toEqual([0]) )
  test('selects first month set when all equal; multi sets',
    () => expect(lib.leastMonthsSet(dayWeightsZero, [[1,4],[2,5],[3,6]])).toEqual([1,4]) )
  test('selects second month when first month is weightier', () => {
    const dayWeights = lib.initDayWeights()
    dayWeights[0][3] = 1 // week 0, month 0, day 3 (Thurs); total 1
    expect(lib.leastMonthsSet(dayWeights, [[0], [1]])).toEqual([1])
    expect(lib.leastMonthsSet(dayWeights, [[0,2], [1,3]])).toEqual([1,3])
  })
})

describe('leastWeekOfMonth', () => {
  // test('selects first week when all equal', () => expect(lib.leastWeekOfMonth(dayWeightsZero, 7)).toBe(0))
  test('selects second week when it is lightest', () => {
    const dayWeights = lib.initDayWeights()
    dayWeights[7*4 + 0] = [1,1,1,1]
    expect(lib.leastWeekOfMonth(dayWeights, 7)).toBe(1)
  })
})
