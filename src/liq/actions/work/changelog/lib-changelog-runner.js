import { addEntry } from './lib-changelog-action-add-entry'
import { finalizeChangelog } from './lib-changelog-action-finalize-entry'

// Setup valid actions
const ADD_ENTRY = 'add-entry'
const FINALIZE_ENTRY = 'finalize-entry'
const validActions = [ ADD_ENTRY, FINALIZE_ENTRY ]

const determineAction = () => {
  const args = process.argv.slice(2)

  if (args.length === 0 || args.length > 1) {
    throw new Error('Unexpected argument count. Please provide exactly one action argument.')
  }

  const action = args[0]
  if (validActions.indexOf(action) === -1) {
    throw new Error(`Invalid action: ${action}`)
  }

  switch (action) {
    case ADD_ENTRY:
      return addEntry
    case FINALIZE_ENTRY:
      return finalizeChangelog
    default:
      throw new Error(`Cannot process unkown action: ${action}`)
  }
}

const execute = () => {
  determineAction().call()
}

export {
  determineAction,
  execute,
  validActions
}
