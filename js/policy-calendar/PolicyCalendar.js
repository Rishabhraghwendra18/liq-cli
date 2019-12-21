import { TsvExt } from '@liquid-labs/policies-model'

const PolicyCalendar = class extends TsvExt {
  /**
  * Item Name : org wide unique calendar item name.
  * Description : Short description of calendar item.
  * Frequency : One of triennial, biennial, annual, semiannual, triannual, quarterly, monthly, weekly.
  * Impact Weighting : Roughly the number of man-hours necessary to complete a task.
  * Span : Number of hours to alot for event. For 8+ hours, span is didvided by 8 and rounded up for span of days.
  */
  static headers = ['Item Name', 'Description', 'Frequency', 'Impact Weighting', 'Span']
  static keys = ['itemName', 'description', 'frequency', 'impactWeighting', 'span']

	constructor(fileName) {
    super(PolicyCalendar.headers, PolicyCalendar.keys, fileName)
	}

  notUnique(data, item) {
    let i
    return -1 !== (i = data.findIndex((line) =>
                                      line[0].toLowerCase() === item.itemName.toLowerCase()))
           && `Policy calendar item '${item.itemName}' already exists at entry ${i + 1}.`
  }

  schedule() {
    const dayWeights = lib.initDayWeights()

    this.reset()
    let item
    while ((item = this.next())) {
      let monthsSets
      switch (item.frequency) {
        case 'quarterly':
          monthsSets = [[0, 3, 6, 9]]; break
        case 'triannual':
          monthsSets = [[0, 4, 8], [1, 5, 9]]; break
        case 'semiannual':
          monthsSets = [[0, 6], [1, 7], [2, 8], [3, 9]]; break
        default:
          monthsSets = [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]]; break
      }

      const leastMonthsSet = lib.leastMonthsSet(dayWeights, monthsSets)

      const leastWeekOfMonth = leastMonthsSet.reduce(
          (combinedWeights, monthIdx) => {
            const weekIdx = (monthIdx - 1) * 4
            return combinedWeights.map((prev, weekOfMonthIdx) =>
                prev + dayWeights[(monthIdx - 1) * 4 + weekIdx]
                  + dayWeights[(monthIdx - 1) * 4 + 1 + idx]
                  + dayWeights[(monthIdx - 1) * 4 + 2 + idx]
                  + dayWeights[(monthIdx - 1) * 4 + 3 + idx]
              )
          },
          [0,0,0,0]
        )
        .reduce((curr, weight, idx) => curr.weight < weight ? curr : { weight: weight, idx: idx })
        .idx
    }
  }

  matchKey = (line, key) => line[0] === key
}

export { PolicyCalendar }
