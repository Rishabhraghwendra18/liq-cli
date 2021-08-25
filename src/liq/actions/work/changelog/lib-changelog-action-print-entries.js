import * as fs from 'fs'

import { readChangelog } from './lib-changelog-core'

const printEntries = (hotfixes, lastReleaseDate) => {
  const changelog = readChangelog()

  // TODO: this is a bit of a limitation requiring the script pwd to be the package root.
  const packageContents = fs.readFileSync('package.json')
  const packageData = JSON.parse(packageContents)

  const changeEntries = changelog.map(r => ({ time : new Date(r.startTimestamp), notes : r.changeNotes, author : r.workInitiator }))
    .concat(hotfixes.map(r => (
      {
        time     : new Date(r.date),
        notes    : [r.message.replace(/^\s*hotfix\s*:?\s*/i, '')],
        author   : r.author.email,
        isHotfix : true
      }
    )))
    .filter(r => r.time >= lastReleaseDate)
  // with Dates, we really want '==', not '==='
  changeEntries.sort((a, b) => a.time < b.time ? -1 : a.time == b.time ? 0 : 1) // eslint-disable-line eqeqeq

  let securityNotes = []
  let drpBcpNotes = []
  let backoutNotes = []

  for (const entry of changelog) {
    if (entry.securityNotes !== undefined) {
      securityNotes = securityNotes.concat(entry.securityNotes)
    }
    if (entry.drpBcpNotes !== undefined) {
      drpBcpNotes = drpBcpNotes.concat(entry.drpBcpNotes)
    }
    if (entry.backoutNotes !== undefined) {
      backoutNotes = backoutNotes.concat(entry.backoutNotes)
    }
  }

  const attrib = (entry) => `_(${entry.author}; ${entry.time.toISOString()})_`

  for (const entry of changeEntries) {
    if (entry.isHotfix) {
      console.log(`* _**hotfix**_: ${entry.notes[0]} ${attrib(entry)}`)
    }
    else {
      for (const note of entry.notes) {
        console.log(`* ${note} ${attrib(entry)}`)
      }
    }
  }
  if (packageData?.liq?.contracts?.secure || securityNotes.length > 0) {
    console.log('\n### Security notes\n\n')
    console.log(`${securityNotes.length === 0 ? '_none_' : `* ${securityNotes.join('\n* ')}`}`)
  }
  if (/* TODO: an org setting org.settings?.['maintains DRP/BCP'] || */ drpBcpNotes.length > 0) {
    console.log('\n### DRP/BCP notes\n\n')
    console.log(`${drpBcpNotes.length === 0 ? '_none_' : `* ${drpBcpNotes.join('\n* ')}`}`)
  }
  if (packageData?.liq?.contracts?.['high availability'] || backoutNotes.length > 0) {
    console.log('\n### Backout notes\n\n')
    console.log(`${backoutNotes.length === 0 ? '_none_' : `* ${backoutNotes.join('\n* ')}`}`)
  }
}

export { printEntries }
