import * as fs from 'fs'
import YAML from 'yaml'

import { readChangelog, requireEnv, saveChangelog } from './lib-changelog-core'

const printEntries = () => {
  const changelog = readChangelog()

  // TODO: this is a bit of a limitation requiring the script pwd to be the package root.
  const packageContents = fs.readFileSync('package.json')
  const packageData = JSON.parse(packageContents)

  let changeNotes = []
  let securityNotes = []
  let drpBcpNotes = []
  let backoutNotes = []

  for (const entry of changelog) {
    changeNotes = changeNotes.concat(entry.changeNotes)
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

  console.log(`* ${changeNotes.join("\n* ")}`)
  if (packageData?.liq?.contracts?.secure || securityNotes.length > 0) {
    console.log("\n### Security notes\n\n")
    console.log(`${securityNotes.length === 0 ? '_none_' : `* ${securityNotes.join("\n* ")}`}`)
  }
  if (/* TODO: an org setting org.settings?.['maintains DRP/BCP'] ||*/ drpBcpNotes.length > 0) {
    console.log("\n### DRP/BCP notes\n\n")
    console.log(`${drpBcpNotes.length === 0 ? '_none_' : `* ${drpBcpNotes.join("\n* ")}`}`)
  }
  if (packageData?.liq?.contracts?.['high availability'] || backoutNotes.length > 0) {
    console.log("\n### Backout notes\n\n")
    console.log(`${backoutNotes.length === 0 ? '_none_' : `* ${backoutNotes.join("\n* ")}`}`)
  }
}

export { printEntries }
