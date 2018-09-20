import * as testing from '../../lib/testing'
const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const expectedWorkUsage = expect.stringMatching(new RegExp(`Valid work actions are:\\s+`))

test('no action results in error and work usage', () => {
  console.error = jest.fn() // supresses err echo from shelljs
  const result = shell.exec(`catalyst work`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`Must specify action.\\s*`))

  expect(result.stdout).toEqual(expectedWorkUsage)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(1)
})

test("'help work' prints work usage", () => {
  const result = shell.exec(`catalyst help work`, execOpts)

  expect(result.stdout).toEqual(expectedWorkUsage)
  expect(result.stderr).toEqual('')
  expect(result.code).toBe(0)
})

const testCheckout = `/tmp/catalyst-test-work-checkout-${testing.randomHex}`
const testOrigin = `/tmp/catalyst-test-work-origin-${testing.randomHex}`

beforeAll(() => {
  // TODO: reuse the checkout from 'project.test.sh'?
  shell.mkdir(testOrigin)
  // TODO: use 'project init'... better yet, once we combine 'work' with 'project', this is folded into a test
  shell.exec(`cd ${testOrigin} && git clone --bare ${testing.selfOriginUrl} .`)
  const initCommand =
    `catalyst ORIGIN_URL="file://${testOrigin}" ORGANIZATION_ID=1234 BILLING_ACCOUNT_ID=4321 project init`
  shell.mkdir(testCheckout)
  shell.exec(`cd ${testCheckout} && ${initCommand}`)
})
afterAll(testing.cleanupDirs(testCheckout, testOrigin))

test("'work start' should require additional arguments", () => {
  const result = shell.exec(`cd ${testCheckout} && catalyst work start`)
  const expectedErr = expect.stringMatching(
    new RegExp(`'work start' requires 1 additional arguments.`))

  expect(result.stdout).toEqual('')
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toEqual(1)
})

test("'work start add-feature' result in new branch", () => {
  const result = shell.exec(`cd ${testCheckout} && catalyst work start add-feature`)
  const expectedOutput = expect.stringMatching(new RegExp(`^Now working on branch '\\d{4}-\\d{2}-\\d{2}-[^-]+-add-feature'.[\\s\\n]*$`))

  expect(result.stdout).toEqual(expectedOutput)
  expect(result.stderr).toEqual('')
  expect(result.code).toEqual(0)

  const branchCheck = shell.exec(`cd ${testCheckout} && git branch | wc -l | awk '{print $1}'`)
  expect(branchCheck.stdout).toEqual("2\n")
  expect(branchCheck.stderr).toEqual('')
  expect(branchCheck.code).toEqual(0)
})

test("'work merge' results merge, push, and deleting branch", () => {
  shell.exec(`echo "hey" > ${testCheckout}/foo.txt`)
  shell.exec(`cd ${testCheckout} && git add foo.txt && git commit -m 'test file'`)
  const result = shell.exec(`cd ${testCheckout} && catalyst work merge`)
  // TODO: test the linecount
  const expectedOutput = expect.stringMatching(new RegExp(`^Work merged and pushed to origin.`))

  expect(result.stdout).toEqual(expectedOutput)
  expect(result.stderr).toEqual('')
  expect(result.code).toEqual(0)

  const branchCheck = shell.exec(`cd ${testCheckout} && git branch | wc -l | awk '{print $1}'`)
  expect(branchCheck.stdout).toEqual("1\n")
  expect(branchCheck.stderr).toEqual('')
  expect(branchCheck.code).toEqual(0)
})
