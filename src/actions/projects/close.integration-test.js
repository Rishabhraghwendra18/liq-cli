import * as testing from '../../lib/testing'

const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

describe(`Command 'liq projects close'`, () => {
  const uncleanErrorCode = 10
  let setupConfig
  let playground

  beforeEach(() => {
    setupConfig = testing.setup()
    setupConfig.metaInit()
    setupConfig.localCheckout()
  })
  afterEach(() => setupConfig.cleanup())

  // afterAll(() => shell.exit(0))

  const closeFailureTests = [
    [ /*desc*/ `should do nothing and emit warning if there are untracked files.`,
      /*setup*/ (setupConfig) => shell.exec(`cd ${setupConfig.localRepoCheckout} && touch foobar`, execOpts),
      // TODO: having trouble matching end to end because of the non-printing coloration characters.
      /*errMatch*/ /Found untracked files./ ],
    [ `should do nothing and emit warning if there are uncommitted changes.`,
      (setupConfig) => shell.exec(`cd ${setupConfig.localRepoCheckout} && echo 'hey' >> README.md`, execOpts),
      /Found uncommitted changes./ ],
    [ `should do nothing and emit warning if there are un-pushed changes.`,
      (setupConfig) => shell.exec(`cd ${setupConfig.localRepoCheckout} && ( echo 'hey' >> README.md && git add README.md && git commit --quiet -m "test commit" )`, execOpts),
      /Local master has not been pushed to upstream master./ ]
  ]

  const progressOutput = /^Checking liquid-labs\/lc-entities-model\.\.\.\s*/m
  test.each(closeFailureTests)(`%s`, (desc, setup, errMatch) => {
    console.error = jest.fn() // supresses err echo from shelljs
    const setupResult = setup(setupConfig)
    expect(setupResult.stderr).toEqual('')
    expect(setupResult.code).toEqual(0)

    let result = shell.exec(`cd ${setupConfig.localRepoCheckout} && HOME=${setupConfig.home} ${testing.LIQ} projects close`, execOpts)
    expect(result.stderr).toMatch(errMatch, "Bash output\n" + result.stderr)
    expect(result.stdout).toMatch(progressOutput)
    expect(result.code).toEqual(uncleanErrorCode)

    result = shell.exec(`cd ${setupConfig.localRepoCheckout} && HOME=${setupConfig.home} ${testing.LIQ} projects close @liquid-labs/lc-entities-model`, execOpts)
    expect(result.stderr).toMatch(errMatch)
    expect(result.stdout).toMatch(progressOutput)
    expect(result.code).toEqual(uncleanErrorCode)
  })

  test(`should remove current project when no changes present`, () => {
    // console.error = jest.fn() // supresses err echo from shelljs
    const expectedOutput =
      /^Checking liquid-labs\/lc-entities-model\.\.\.\s*Removed local work directory for project '@liquid-labs\/lc-entities-model'/m
    const result = shell.exec(`cd ${setupConfig.localRepoCheckout} && HOME=${setupConfig.home} ${testing.LIQ} projects close`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(expectedOutput)
    expect(result.code).toEqual(0)
    expect(shell.ls(`${setupConfig.playground}/liquid_labs`)).toHaveLength(0)
  })

  test(`should remove specified project when no changes present`, () => {
    console.error = jest.fn() // supresses err echo from shelljs
    const expectedOutput =
      /^Checking liquid-labs\/lc-entities-model\.\.\.\s*Removed local work directory for project '@liquid-labs\/lc-entities-model'/m
    const result = shell.exec(`HOME=${setupConfig.home} ${testing.LIQ} projects close @liquid-labs/lc-entities-model`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(expectedOutput)
    expect(result.code).toEqual(0)
    expect(shell.ls(`${setupConfig.playground}/liquid_labs`)).toHaveLength(0)
  })
})
