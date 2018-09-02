const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const randomHex = Math.floor((1 + Math.random()) * 0x1000000000000)
  .toString(16)
  .substring(1)

beforeAll(() => { console.log('before: ' + randomHex) })
afterAll(() => { console.log('after') })

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
