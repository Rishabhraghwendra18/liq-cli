const initDayWeights = () => new Array(4 * 10).fill(0).map(() => [0,0,0,0])

/**
 * Takes an array of numbers inidcating a set of (zero-indexed) months and combines all the weights to a single number,
 * rperesenting the weight of the month-set.
 */
const combineMonthsWeight = (dayWeights, monthsSet) =>
  monthsSet.reduce(
    (acc, monthIdx) => {
      const week1Idx = monthIdx * 4
      return [0,1,2,3].reduce(
        (acc, weekOfMonth) =>
          acc + dayWeights[week1Idx + weekOfMonth].reduce((acc, dayWeight) => acc + dayWeight, 0),
        acc
      )
    },
    0
  )

/**
 * Given a collection of month-sets, selects the least weigthed month-set.
 */
const leastMonthsSet = (dayWeights, monthsSets) => {
  return monthsSets[monthsSets.reduce(
    (currLeast, monthsSet, setIdx) => {
      const monthsSetWeight = combineMonthsWeight(dayWeights, monthsSet)

      return monthsSetWeight < currLeast.weight || currLeast.idx === -1 ?
        {weight: monthsSetWeight, idx: setIdx} :
        currLeast
    },
    {weight: 0, idx: -1}
  ).idx]
}

/**
 * Given a month, selects the index of the lightest week of that month.
 */
const leastWeekOfMonth = (dayWeights, month) =>
  [0, 1, 2, 3].map(
    (weekOfMonth) => dayWeights[month * 4 + weekOfMonth].reduce((total, dayWeight) => total + dayWeight, 0)
  ).reduce(
    (currLeast, weekWeight, idx) =>
      currLeast === undefined || weekWeight < currLeast.weight ? { weight: weekWeight, idx: idx } : currLeast,
    undefined
  ).idx

/**
 * Given a set of week weights (1-d array), will return an array of the indexes of that array such that the indexes
 * applied to the weights give a least to most result.
 */
const orderWeek = (weekWeights) => {
  const testOrder = []
  let minCut = -1
  while (testOrder.length < 3) {
    let resultWeight = -1
    const idx = weekWeights.reduce((result, weight, idx) => {
      if (weight > minCut && weight < resultWeight) {
        resultWeight = weight
        return idx
      }
      else return result
    })
    testOrder.push(idx)
  }
  return testOrder
}

/*const scheduleInWeek = (weekWeights, calendarItem) => {
  if (!orderWeek(weekWeights).some(())
}*/

export {
  initDayWeights,
  combineMonthsWeight,
  leastMonthsSet,
  leastWeekOfMonth
}
