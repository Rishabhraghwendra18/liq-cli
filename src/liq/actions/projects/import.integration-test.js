import * as testing from '../../lib/testing'

const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

describe(`Command 'liq projects import'`, () => {
  let testConfig
  let playground

  beforeEach(() => {
    testConfig = testing.setup()
    testConfig.metaInit()
    playground = `${testConfig.home}/playground`
  })
  afterEach(() => testConfig.cleanup())

  // afterAll(() => shell.exit(0))

  test.each([
        // TODO: provide a case that's not part of an org
        // ['liq-cli', 'liq-cli'],
        ['@liquid-labs/lc-entities-model', 'liquid-labs/lc-entities-model'],
        ['https://github.com/liquid-labs/lc-entities-model', 'liquid-labs/lc-entities-model'],
        [testing.localRepoUrl, 'liquid-labs/lc-entities-model']])
      ("with '--no-fork %s' successfully clone project.", (importSpec, projectName) => {
    const result = shell.exec(`HOME=${testConfig.home} ${testing.LIQ} projects import --no-install --no-fork ${importSpec}`, execOpts)
    const expectedOutput = new RegExp(`'@${projectName}' imported into playground.[\s\n]*$`)

    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(expectedOutput)
    expect(result.code).toEqual(0);
    ['README.md', '.git'].forEach((i) => expect(shell.test('-e', `${playground}/${projectName}/${i}`)).toBe(true))
  })
})
