import * as fs from 'fs'

const clPath = process.env.CHANGELOG_FILE

const changelogContents = fs.readFileSync(clPath)
const changelog = JSON.parse(changelogContents)

console.log(changelog)
