import { TsvExt } from '@liquid-labs/policies-model'

const PolicyCalendar = class extends TsvExt {
  /**
  * Item Name : org wide unique calendar item name.
  * Description : Short description of calendar item.
  * Frequency : One of triennial, biennial, annual, semiannual, triannual, quarterly, bimonhtly, monthly, weekly.
  * Impact Weighting : Roughly the number of man-hours necessary to complete a task.
  * Span : Number of hours to alot for event. For 8+ hours, span is didvided by 8 and rounded up for span of days.
  */
  static headers = ['Item Name', 'Description', 'Frequency', 'Impact Weighting', 'Span']
  static keys = ['itemName', 'description', 'frequency', 'impactWeighting', 'span']
  static BIENNIAL_SELECTOR = ['ODD', 'EVEN']
  static TRIENNIAL_SELECTOR = ['ODD', 'EVEN', 'TRIPLETS']

  constructor(fileName) {
    super(PolicyCalendar.headers, PolicyCalendar.keys, fileName)
  }

  notUnique(data, item) {
    let i
    return (i = data.findIndex((line) =>
      line[0].toLowerCase() === item.itemName.toLowerCase())) !== -1
           && `Policy calendar item '${item.itemName}' already exists at entry ${i + 1}.`
  }

  /**
   * Generates an iniital, balanced, concrete schedule based on the Policy calendar requirements.
   */
  schedule() {
    const dayWeights = lib.initDayWeights()
    const biennialIdx = 0
    const triennialIdx = 0

    this.reset()
    let item
    while ((item = this.next())) {
      let monthsSets
      switch (item.frequency) {
      case 'weekly':
      case 'monthly':
        monthsSets = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]]; break
      case 'bimonthly':
        monthsSets = [[0, 2, 4, 6, 8, 10], [1, 3, 5, 7, 9, 11]]; break
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

      // For sub-annual items, we don't try to align weeks, just months, so earch occurance will be scheduled
      // independently.
      leastMonthsSet.forEach((month) => {
        const leastWeekOfMonth = lib.leastWeekOfMonth(dayWeights, month)
        const policyEvent = lib.scheduleInWeek(dayWeights[month * 4 + leastWeekOfMonth], item)
      })
    } // while ...this.next()
  } // schedule()

  matchKey = (line, key) => line[0] === key
}

export { PolicyCalendar }
