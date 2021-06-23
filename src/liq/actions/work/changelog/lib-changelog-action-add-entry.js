import dateFormat from 'dateformat'

import { readChangelog, requireEnv, saveChangelog } from './lib-changelog-core'

const createNewEntry = (changelog) => {
  // get the approx start time according to the local clock
  const startTimestampLocal = dateFormat(new Date(), 'UTC:yyyy-mm-dd-HHMM Z')
  // process the 'work unit' data
  const issues = requireEnv('WORK_ISSUES').split('\n')
  const involvedProjects = requireEnv('INVOLVED_PROJECTS').split('\n')

  const newEntry = {
    issues,
    branch          : requireEnv('WORK_BRANCH'),
    startTimestampLocal,
    branchFrom      : requireEnv('CURR_REPO_VERSION'),
    description     : requireEnv('WORK_DESC'),
    workInitiator   : requireEnv('WORK_INITIATOR'),
    branchInitiator : requireEnv('CURR_USER'),
    involvedProjects
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
