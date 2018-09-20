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

const testWorkspaceDir = `/tmp/catalyst-test-project-workspace-${testing.randomHex}`
const testProjectDir = `${testWorkspaceDir}/catalyst-cli`

beforeAll(() => {
  shell.mkdir(testWorkspaceDir)
})
// afterAll(testing.cleanupDirs(testWorkspaceDir))

test(`'setup workspace'`, () => {
  const result = shell.exec(`cd ${testWorkspaceDir} && catalyst workspace init`)
  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual('')
  expect(result.code).toEqual(0)
})

test("'project import' should clone remote git into workspace", () => {
  const importCommand = `catalyst project import "${testing.selfOriginUrl}"`
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

test(`'project close' should do nothing and emit warning if there are untracked files.`, () => {
  shell.exec(`cd ${testProjectDir} && touch foobar`, execOpts)
  // TODO: having trouble matching end to end because of the non-printing coloration characters.
  const expectedErr = /Found untracked files./

  let result = shell.exec(`cd ${testProjectDir} && catalyst project close`)
  expect(result.stderr).toMatch(expectedErr)
  expect(result.stdout).toEqual('')
  expect(result.code).toEqual(1)

  result = shell.exec(`cd ${testWorkspaceDir} && catalyst project close catalyst-cli`)
  expect(result.stderr).toMatch(expectedErr)
  expect(result.stdout).toEqual('')
  expect(result.code).toEqual(1)

  shell.exec(`cd ${testProjectDir} && rm foobar`, execOpts)
})
