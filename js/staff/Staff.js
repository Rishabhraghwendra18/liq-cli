import { TsvExt } from '@liquid-labs/policies-model'

const Staff = class extends TsvExt {
  static headers = ['Email', 'Family Name', 'Given Name', 'Start Date']
  static keys = ['email', 'familyName', 'givenName', 'startDate']

  constructor(fileName) {
    super(Staff.headers, Staff.keys, fileName)
  }

  notUnique(data, item) {
    let i
    return (i = data.findIndex((line) =>
      line[0].toLowerCase() === item.email.toLowerCase())) !== -1
           && `Staff member with email '${item.email}' already exists at entry ${i + 1}.`
  }

  matchKey = (line, key) => line[0] === key
}

export { Staff }
