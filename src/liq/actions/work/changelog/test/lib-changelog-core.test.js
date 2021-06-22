// globals describe expect test
import * as fs from 'fs'

import { ADD_ENTRY, determineAction, readChangelog, requireEnv, saveChangelog } from '../lib-changelog-core'

const TEST_CHANGELOG_PATH='./src/liq/actions/work/changelog/test/test-changelog.json'

describe('determineAction', () => {
  let origArgv
  beforeAll(() => { origArgv = process.argv })
  afterAll(() => { process.argv = origArgv })

  test("extracts action from 'process.argv'", () => {
    process.argv = [ 'node', 'script', 'add-entry' ]
    expect(determineAction()).toBe(ADD_ENTRY)
  })

  test('raises an error when no args provided', () => {
    process.argv = [ 'node', 'script' ]
    expect(determineAction).toThrow()
  })

  test('raises an error when too many args provided', () => {
    process.argv = [ 'node', 'script', 'blah', 'foo' ]
    expect(determineAction).toThrow()
  })

  test('raises error on unkown action and reports it', () => {
    process.argv = [ 'node', 'script', 'blah' ]
    expect(determineAction).toThrow(/blah/)
  })
})

describe('requireEnv', () => {
  test('returns the value of an environment variable', () => {
    process.env.FOO = 'foo'
    expect(requireEnv('FOO')).toBe('foo')
  })

  test('raises an error when an environment variable is not found and reports it', () => {
    expect(() => requireEnv('BAR')).toThrow(/BAR/)
  })
})

describe('IO functions', () => {
  let testChangelog
  beforeAll(() => {
    testChangelog = JSON.parse(fs.readFileSync(TEST_CHANGELOG_PATH))
  })

  describe('readChangelog', () => {
    test('can read an existing changelog file', () => {
      process.env.CHANGELOG_FILE = TEST_CHANGELOG_PATH
      const changelog = readChangelog()
      expect(changelog).toEqual(testChangelog)
    })
  })

  describe('saveChangelog', () => {
    test('will save the provided changelog file', () => {
      process.env.CHANGELOG_FILE = './test-staging/save-changelog.json'
      saveChangelog(testChangelog)
      expect(readChangelog()).toEqual(testChangelog)
    })
  })
})
