import * as fs from 'fs'

// Declare valid actions
const ADD_ENTRY="add-entry"
const validActions = [ ADD_ENTRY ]

const determineAction = () => {
  var args = process.argv.slice(2)

  if (args.length === 0 || args.length > 1) {
    throw new Error(`Unexpected argument count. Please provide exactly one action argument.`)
  }

  const action = args[0]
  if (validActions.indexOf(action) === -1) {
    throw new Error(`Invalid action: ${action}`)
  }

  return action
}

const readChangelog = () => {
  const clPath = process.env.CHANGELOG_FILE

  const changelogContents = fs.readFileSync(clPath)
  const changelog = JSON.parse(changelogContents)

  return changelog
}

const requireEnv = (key) => {
  return process.env[key] || throw new Error(`Did not find required environment parameter: ${key}`)
}

export {
  ADD_ENTRY,
  determineAction,
  readChangelog,
  requireEnv
}
