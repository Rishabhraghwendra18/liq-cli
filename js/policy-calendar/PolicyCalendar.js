import { TsvExt } from '@liquid-labs/policies-model'

const PolicyCalendar = class extends TsvExt {
  static headers = ['Item Name', 'Description', 'Frequency', 'Impact Weighting']
  static keys = ['itemName', 'description', 'frequency', 'impactWeighting']

	constructor(fileName) {
    super(PolicyCalendar.headers, PolicyCalendar.keys, fileName)
	}

  notUnique(data, item) {
    let i
    return -1 !== (i = data.findIndex((line) =>
                                      line[0].toLowerCase() === item.itemName.toLowerCase()))
           && `Policy calendar item '${item.itemName}' already exists at entry ${i + 1}.`
  }

  matchKey = (line, key) => line[0] === key
}

export { PolicyCalendar }
