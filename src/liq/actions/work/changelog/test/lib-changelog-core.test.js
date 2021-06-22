/* globals afterAll, beforeAll, describe, expect, test */
import * as fs from 'fs'

import { readChangelog, requireEnv, saveChangelog } from '../lib-changelog-core'

const TEST_CHANGELOG_PATH = './src/liq/actions/work/changelog/test/test-changelog.json'

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
