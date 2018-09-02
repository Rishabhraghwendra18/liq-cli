const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const expectedWorkUsage = expect.stringMatching(new RegExp(`Valid work actions are:\\s+
start <desc> : creates work branch and switches to it[.\\s]+`, 'm'))

test('no action results in error and work usage', () => {
  console.error = jest.fn() // supresses err echo from shelljs
  const result = shell.exec(`gcproj work`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`Must specify action.\\s*`))

  expect(result.stdout).toEqual(expectedWorkUsage)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(1)
})

test("'help work' prints work usage", () => {
  const result = shell.exec(`gcproj help work`, execOpts)

  expect(result.stdout).toEqual(expectedWorkUsage)
  expect(result.stderr).toEqual('')
  expect(result.code).toBe(0)
})

const randomHex = Math.floor((1 + Math.random()) * 0x1000000000000)
  .toString(16)
  .substring(1)
const testCheckout = `/tmp/gcproj-test-checkout-${randomHex}`
const testOrigin = `/tmp/gcproj-test-origin-${randomHex}`

let gitSetupResults
beforeAll(() => {
  if (!shell.which('git')) {
    throw new Error('git must be installed to execute tests.')
  }
  shell.mkdir(testCheckout)
  shell.mkdir(testOrigin)
  const { code, stderr } = shell.exec(`cd ${testOrigin} && git init --bare`)
  if (code !== 0) {
    throw new Error(`could not initialize test origin: ${stderr}`)
  }
})
afterAll(() => {
  shell.rm('-rf', testCheckout)
  shell.rm('-rf', testOrigin)
})

test('project init should clone remote git dir', () => {
  gitSetupResults = shell.exec('gcproj project init')
})
