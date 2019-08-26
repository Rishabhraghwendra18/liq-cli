const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

import * as testing from '../../lib/testing'
export const testPlayground = `/tmp/catalyst-test-playground-${testing.randomHex}`
export const testOriginDir = `/tmp/catalyst-test-gitorigin-${testing.randomHex}`
export const testCheckoutDir = `${testPlayground}/test-checkout`
const testProjectDir = `${testPlayground}/catalyst-cli`

describe(`Command 'catalyst meta setup'`, () => {
  /*
  beforeAll(() => {
    shell.mkdir(testPlayground)
    shell.mkdir(testOriginDir)
    shell.exec(`cd ${testOriginDir} && git clone -q --bare ${testing.selfOriginUrl} .`)
  })*/

  const importCommand = `catalyst project import "${testing.selfOriginUrl}"`
  test("'project import' should clone remote git into playground", () => {
    const expectedOutput = expect.stringMatching(
      new RegExp(`^'catalyst-cli' imported into playground.[\s\n]*$`))
    const result = shell.exec(`cd ${testPlayground} && ${importCommand}`)

    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual(expectedOutput)
    expect(result.code).toEqual(0)
    const checkFiles = ['README.md', 'dev_notes.md', '.git', '.catalyst-pub'].map((i) =>
      `${testProjectDir}/${i}`)
    expect(shell.ls('-d', checkFiles)).toHaveLength(4)
  })

  closeFailureTests = [
    { desc: `'project close' should do nothing and emit warning if there are untracked files.`,
      setup: () => shell.exec(`cd ${testProjectDir} && touch foobar`, execOpts),
      // TODO: having trouble matching end to end because of the non-printing coloration characters.
      errMatch: /Found untracked files./,
      cleanup: () => shell.exec(`cd ${testProjectDir} && rm foobar`, execOpts) },
    { desc: `'project close' should do nothing and emit warning if there are uncommitted changes.`,
      setup: () => shell.exec(`cd ${testProjectDir} && echo 'hey' >> README.md`, execOpts),
      errMatch: /Found uncommitted changes./,
      cleanup: () => shell.exec(`cd ${testProjectDir} && git checkout README.md`, execOpts) },
    { desc: `'project close' should do nothing and emit warning if there are un-pushed changes.`,
      setup: () => shell.exec(`cd ${testProjectDir} && echo 'hey' >> README.md && git commit --quiet -am "test commit"`, execOpts),
      errMatch: /Not all changes have been pushed to master./,
      cleanup: () => shell.exec(`cd ${testProjectDir} && git reset --hard HEAD^`, execOpts) },
  ]

  closeFailureTests.forEach(testConfig => {
    test(testConfig.desc, () => {
      console.error = jest.fn() // supresses err echo from shelljs
      testConfig.setup()

      let result = shell.exec(`cd ${testProjectDir} && catalyst project close`, execOpts)
      expect(result.stderr).toMatch(testConfig.errMatch)
      expect(result.stdout).toEqual('')
      expect(result.code).toEqual(1)

      result = shell.exec(`cd ${testPlayground} && catalyst project close catalyst-cli`, execOpts)
      expect(result.stderr).toMatch(testConfig.errMatch)
      expect(result.stdout).toEqual('')
      expect(result.code).toEqual(1)

      testConfig.cleanup()
    })
  })

  test(`project directory is removed on 'project closed' when no changes present`, () => {
    console.error = jest.fn() // supresses err echo from shelljs
    const expectedOutput = /^Removed project 'catalyst-cli'/
    let result = shell.exec(`cd ${testProjectDir} && catalyst project close`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(expectedOutput)
    expect(result.code).toEqual(0)
    expect(shell.ls(testPlayground)).toHaveLength(0)

    shell.exec(`cd ${testPlayground} && ${importCommand}`)

    result = shell.exec(`cd ${testPlayground} && catalyst project close catalyst-cli`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(expectedOutput)
    expect(result.code).toEqual(0)
    expect(shell.ls(testPlayground)).toHaveLength(0)
  })

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
})
