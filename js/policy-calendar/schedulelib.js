const initDayWeights = () => new Array(4 * 10).fill(0).map(() => [0,0,0,0])

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

export {
  initDayWeights,
  combineMonthsWeight,
  leastMonthsSet
}
