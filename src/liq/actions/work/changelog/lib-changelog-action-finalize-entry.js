import simpleGit from 'simple-git'

import { readChangelog, requireEnv, saveChangelog } from './lib-changelog-core'

const finalizeCurrentEntry = async(changelog) => {
  const currentEntry = changelog[0]

  // update the involved projects
  const involvedProjects = requireEnv('INVOLVED_PROJECTS').split('\n')
  currentEntry.involvedProjects = involvedProjects

  const branchFrom = currentEntry.branchFrom
  const gitOptions = {
    baseDir                : process.cwd(),
    binary                 : 'git',
    maxConcurrentProcesses : 6
  }
  const git = simpleGit(gitOptions)
  const results = await git.raw('shortlog', '--summary', '--email', `${branchFrom}...HEAD`)
  const contributors = results
    .split('\n')
    .map((l) => l.replace(/^[\s\d]+\s+/, ''))
    .filter((l) => l.length > 0)
  currentEntry.contributors = contributors

  /*
  "qa": {
     "testedVersion": "bf820e318...",
     "unitTestReport": "https://...",
     "lintReport": "https://..."
  }
  */
  return currentEntry
}

const finalizeChangelog = async() => {
  const changelog = readChangelog()
  await finalizeCurrentEntry(changelog)
  saveChangelog(changelog)
}

export { finalizeCurrentEntry, finalizeChangelog }
