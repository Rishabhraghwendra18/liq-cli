// TODO: once we've updated all our old 'changelog.json' formats, we can drop this. There are no examples 'in the wild' that we need to worry about.

import * as fs from 'fs'
import { requireEnv, saveChangelog } from './lib-changelog-core'

const readOldChangelog = () => {
  const clPath = requireEnv('CHANGELOG_FILE')
  const oldClPath = `${clPath.substring(0, clPath.length - 5)}.json`

  const oldClContents = fs.readFileSync(oldClPath)
  const oldCl = JSON.parse(oldClContents)

  return oldCl
}

const convertFormat = (changelog) => {
  changelog.reverse() // in-place modification
  for (const entry of changelog) {
    const newStart = new Date()
    newStart.setTime(0)
    // old format: UTC:yyyy-mm-dd-HHMM Z
    const [year, month, date, time] = entry.startTimestampLocal.split(' ')[0].split('-')
    const hour = time.substring(0, 2)
    const minutes = time.substring(2)

    newStart.setUTCFullYear(year)
    newStart.setUTCMonth(month - 1)
    newStart.setUTCDate(date)
    newStart.setUTCHours(hour)
    newStart.setUTCMinutes(minutes)

    entry.startTimestamp = newStart.toISOString()
    delete entry.startTimestampLocal

    entry.startEpochMillis = newStart.getTime()

    entry.changeNotes = [entry.description]
    delete entry.description

    entry.securityNotes = []
    entry.drpBcpNotes = []
    entry.backoutNotes = []
  }

  return changelog
}

const updateFileFormat = () => {
  const oldCl = readOldChangelog()
  const changelog = convertFormat(oldCl)
  saveChangelog(changelog)
}

export { convertFormat, updateFileFormat }
