// These tests are designed to be run sequentially and are kicked off by
// 'seqtests.test.js'.
import * as testing from '../../lib/testing'
const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const expectedProjectUsage = expect.stringMatching(new RegExp(`Valid project actions are:`))

test('no action results in error and project usage', () => {
  console.error = jest.fn() // supresses err echo from shelljs
  const result = shell.exec(`catalyst project`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`Must specify action.\\s*`))

  expect(result.stderr).toEqual(expectedErr)
  expect(result.stdout).toEqual(expectedProjectUsage)
  expect(result.code).toBe(1)
})

test("'help work' prints project usage", () => {
  const result = shell.exec(`catalyst help project`, execOpts)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedProjectUsage)
  expect(result.code).toBe(0)
})

export const testWorkspaceDir = `/tmp/catalyst-test-workspace-${testing.randomHex}`
export const testOriginDir = `/tmp/catalyst-test-gitorigin-${testing.randomHex}`
export const testCheckoutDir = `${testWorkspaceDir}/test-checkout`
const testProjectDir = `${testWorkspaceDir}/catalyst-cli`

beforeAll(() => {
  shell.mkdir(testWorkspaceDir)
  shell.mkdir(testOriginDir)
  shell.exec(`cd ${testOriginDir} && git clone -q --bare ${testing.selfOriginUrl} .`)
})

test(`'setup workspace'`, () => {
  const result = shell.exec(`cd ${testWorkspaceDir} && catalyst workspace init`)
  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual('')
  expect(result.code).toEqual(0)
})

const importCommand = `catalyst project import "${testing.selfOriginUrl}"`
test("'project import' should clone remote git into workspace", () => {
  const expectedOutput = expect.stringMatching(
    new RegExp(`^'catalyst-cli' imported into workspace.[\s\n]*$`))
  const result = shell.exec(`cd ${testWorkspaceDir} && ${importCommand}`)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOutput)
  expect(result.code).toEqual(0)
  const checkFiles = ['README.md', 'dev_notes.md', '.git', '.catalyst-pub'].map((i) =>
    `${testProjectDir}/${i}`)
  expect(shell.ls('-d', checkFiles)).toHaveLength(4)
})

const closeFailureTests = [
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

    result = shell.exec(`cd ${testWorkspaceDir} && catalyst project close catalyst-cli`, execOpts)
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
  expect(shell.ls(testWorkspaceDir)).toHaveLength(0)

  shell.exec(`cd ${testWorkspaceDir} && ${importCommand}`)

  result = shell.exec(`cd ${testWorkspaceDir} && catalyst project close catalyst-cli`, execOpts)
  expect(result.stderr).toEqual('')
  expect(result.stdout).toMatch(expectedOutput)
  expect(result.code).toEqual(0)
  expect(shell.ls(testWorkspaceDir)).toHaveLength(0)
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
