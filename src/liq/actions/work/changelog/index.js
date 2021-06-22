import { ADD_ENTRY, determineAction, readChangelog, saveChangelog } from './lib-changelog-core'
import { addEntry } from './lib-changelog-action-add-entry'

// Main semantic body
const action = determineAction()
const changelog = readChangelog()
switch (action) {
case ADD_ENTRY:
  addEntry(changelog)
  saveChangelog(changelog); break
default:
  throw new Error(`Unexpected unknown action snuck through: ${action}`)
}
