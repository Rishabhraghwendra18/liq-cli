const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const expectedUsage = expect.stringMatching(`Usage:

proj <component | global action> <action> [<action args>]

global actions:\\.+`)

test('no argument results in usage and error', () => {
  console.error = jest.fn() // supresses err echo from shelljs
  const result = shell.exec(`gcproj`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`Invalid invocation. See usage above.\\s*`))

  expect(result.stdout).toEqual(expectedUsage)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(1)
})

test('invalid global action results in usage and error', () => {
  const badGlobal = 'no-such-global-action'
  console.error = jest.fn() // supresses err echo from shelljs
  const result = shell.exec(`gcproj ${badGlobal}`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`No such component or global action '${badGlobal}'.\\s*`))

  expect(result.stdout).toEqual(expectedUsage)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(1)
})

test('help should print usage', () => {
  const result = shell.exec(`gcproj help`, execOpts)

  expect(result.stdout).toEqual(expectedUsage)
  expect(result.stderr).toEqual('')
  expect(result.code).toBe(0)
})
