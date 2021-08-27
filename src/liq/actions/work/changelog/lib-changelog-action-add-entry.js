import { readChangelog, requireEnv, saveChangelog } from './lib-changelog-core'

const createNewEntry = (changelog) => {
  // get the approx start time according to the local clock
  const now = new Date()
  const startTimestamp = now.toISOString()
  const startEpochMillis = now.getTime()
  // process the 'work unit' data
  const issues = requireEnv('WORK_ISSUES').split('\n')
  const involvedProjects = requireEnv('INVOLVED_PROJECTS').split('\n')

  const newEntry = {
    startTimestamp,
    startEpochMillis,
    issues,
    branch          : requireEnv('WORK_BRANCH'),
    branchFrom      : requireEnv('CURR_REPO_VERSION'),
    workInitiator   : requireEnv('WORK_INITIATOR'),
    branchInitiator : requireEnv('CURR_USER'),
    involvedProjects,
    changeNotes     : [requireEnv('WORK_DESC')],
    securityNotes   : [],
    drpBcpNotes     : [],
    backoutNotes    : []
  }

  changelog.push(newEntry)
  return newEntry
}

const addEntry = () => {
  const changelog = readChangelog()
  createNewEntry(changelog)
  saveChangelog(changelog)
}

export { addEntry, createNewEntry }
