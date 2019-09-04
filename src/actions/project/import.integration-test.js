import * as testing from '../../lib/testing'

const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

describe(`Command 'catalyst project import'`, () => {
  let testConfig
  let playground
  beforeEach(() => {
    testConfig = testing.setup()
    testConfig.metaInit()
    playground = `${testConfig.home}/playground`
  })
  afterEach(() => testConfig.cleanup())

  test.each([
        ['catalyst-cli', 'catalyst-cli'],
        ['@liquid-labs/lc-entities-model', '@liquid-labs/lc-entities-model'],
        ['https://github.com/Liquid-Labs/lc-entities-model', '@liquid-labs/lc-entities-model'],
        [testing.localRepoUrl, '@liquid-labs/lc-entities-model']])
      ("with '%s' successfully clone project.", (importSpec, projectName) => {
    const result = shell.exec(`HOME=${testConfig.home} catalyst project import ${importSpec}`, execOpts)
    const expectedOutput = new RegExp(`^'${projectName}' imported into playground.[\s\n]*$`)

    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(expectedOutput)
    expect(result.code).toEqual(0);
    ['README.md', '.git'].forEach((i) => expect(shell.test('-e', `${playground}/${projectName}/${i}`)).toBe(true))
  })

/*
  test(`project setup in bare directory`, () => {
    shell.mkdir(testCheckoutDir)
    const initCommand =
      `catalyst ORIGIN_URL="file://${testOriginDir}" CURR_ENV_GCP_ORG_ID=1234 CURR_ENV_GCP_BILLING_ID=4321 project setup`
    const result = shell.exec(`cd ${testCheckoutDir} && ${initCommand}`)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch('')
    expect(result.code).toEqual(0)
    expect(shell.test('-f', `${testCheckoutDir}/.catalyst`)).toEqual(true)
    expect(shell.test('-f', `${testCheckoutDir}/.catalyst-pub`)).toEqual(true)
    shell.exec(`cd ${testCheckoutDir} && git add .catalyst-pub && git commit -qm "added .catalyst-pub"`)
  })
  */
})
