import * as testing from '../../lib/testing'

const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

describe(`'catalyst meta init'`, () =>{
  let testConfig
  beforeEach(() => {
    testConfig = testing.setup()
  })
  afterEach(() => testConfig.cleanup())

  test(`with no argument should ask for playground and initialize the liq DB and playground`, () => {
    let result = shell.exec(`HOME=${testConfig.testHome} catalyst meta init <<< $(echo)`, execOpts)

    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(new RegExp(`(Creating.*success[^\\\\n]*){5}(Initializing.*success[^\\\\n]*)`, 'm'))
    expect(result.code).toEqual(0)

    expect(shell.test('-d', `${testConfig.testHome}/.liquid-development`)).toBe(true)
    expect(shell.test('-d', `${testConfig.testHome}/.liquid-development/environments`)).toBe(true)
    expect(shell.test('-d', `${testConfig.testHome}/.liquid-development/work`)).toBe(true)
    expect(shell.test('-d', `${testConfig.testHome}/playground`)).toBe(true)
    expect(shell.test('-f', `${testConfig.testHome}/.liquid-development/settings.sh`)).toBe(true)

    result = shell.exec(`source "${testConfig.testHome}/.liquid-development/settings.sh"; echo -n $LIQ_PLAYGROUND`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual(`${testConfig.testHome}/playground`)
    expect(result.code).toEqual(0)
  })
})
