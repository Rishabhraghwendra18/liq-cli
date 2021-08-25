import { addEntry } from './lib-changelog-action-add-entry'
import { finalizeChangelog } from './lib-changelog-action-finalize-entry'
import { printEntries } from './lib-changelog-action-print-entries'
import { updateFileFormat } from './lib-changelog-action-update-format'

// Setup valid actions
const ADD_ENTRY = 'add-entry'
const FINALIZE_ENTRY = 'finalize-entry'
const PRINT_ENTRIES = 'print-entries'
const UPDATE_FORMAT = 'update-format'
const validActions = [ADD_ENTRY, FINALIZE_ENTRY, PRINT_ENTRIES, UPDATE_FORMAT]

const determineAction = () => {
  const args = process.argv.slice(2)

  if (args.length === 0) { // || args.length > 1) { TODO: we do need args for 'print-changelog'...
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
  case PRINT_ENTRIES:
    return () => printEntries(JSON.parse(args[1]), new Date(args[2]))
  case UPDATE_FORMAT:
    return updateFileFormat
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
