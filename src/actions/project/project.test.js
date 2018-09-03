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

  expect(result.stdout).toEqual(expectedProjectUsage)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(1)
})

test("'help work' prints project usage", () => {
  const result = shell.exec(`catalyst help project`, execOpts)

  expect(result.stdout).toEqual(expectedProjectUsage)
  expect(result.stderr).toEqual('')
  expect(result.code).toBe(0)
})

const randomHex = Math.floor((1 + Math.random()) * 0x1000000000000)
  .toString(16)
  .substring(1)
const testCheckout = `/tmp/catalyst-test-checkout-${randomHex}`
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
    `catalyst ORIGIN_URL="${testOriginUrl}" ORGANIZATION_ID=1234 BILLING_ACCOUNT_ID=4321 project init`
  const expectedOutput = expect.stringMatching(
    new RegExp(`^Cloned 'http[^']+' into '${testCheckout}'.[\s\n]*Updated .+.catalyst'\.[\s\n]*$`))
  const result =
    shell.exec(`cd ${testCheckout} && ${initCommand}`)

  expect(result.stdout).toEqual(expectedOutput)
  expect(result.stderr).toEqual('')
  expect(result.code).toEqual(0)
  const checkFiles = ['README.md', 'dev_notes.md', '.git', '.catalyst'].map((i) =>
    `${testCheckout}/${i}`)
  expect(shell.ls('-d', checkFiles)).toHaveLength(4)
})
