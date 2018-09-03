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
const testOriginUrl = 'https://github.com/Liquid-Labs/catalyst-cli.git'

let gitSetupResults
beforeAll(() => {
  shell.mkdir(testCheckout)
})
afterAll(() => {
  shell.rm('-rf', testCheckout)
})

test('project init should clone remote git dir', () => {
  const initCommand =
    `gcproj ORIGIN_URL="${testOriginUrl}" ORGANIZATION_ID=1234 BILLING_ACCOUNT_ID=4321 project init`
  const expectedOutput = expect.stringMatching(
    new RegExp(`^Cloned 'http[^']+' into '${testCheckout}'.[\s\n]*Updated .+gcprojfile'\.[\s\n]*$`))
  const result =
    shell.exec(`cd ${testCheckout} && ${initCommand}`)

  expect(result.stdout).toEqual(expectedOutput)
  expect(result.stderr).toEqual('')
  expect(result.code).toEqual(0)
  const checkFiles = ['README.md', 'dev_notes.md', '.git'].map((i) =>
    `${testCheckout}/${i}`)
  expect(shell.ls('-d', checkFiles)).toHaveLength(3)
})
