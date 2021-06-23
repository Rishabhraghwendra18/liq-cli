/* globals afterAll, beforeAll, describe, expect, test */
import { determineAction } from '../lib-changelog-runner'
import { addEntry } from '../lib-changelog-action-add-entry'

describe('determineAction', () => {
  let origArgv
  beforeAll(() => { origArgv = process.argv })
  afterAll(() => { process.argv = origArgv })

  // TODO: use 'validActions' to test each of the actions
  test("extracts action from 'process.argv'", () => {
    process.argv = ['node', 'script', 'add-entry']
    expect(determineAction()).toBe(addEntry)
  })

  test('raises an error when no args provided', () => {
    process.argv = ['node', 'script']
    expect(determineAction).toThrow()
  })

  test('raises an error when too many args provided', () => {
    process.argv = ['node', 'script', 'blah', 'foo']
    expect(determineAction).toThrow()
  })

  test('raises error on unkown action and reports it', () => {
    process.argv = ['node', 'script', 'blah']
    expect(determineAction).toThrow(/blah/)
  })
})
