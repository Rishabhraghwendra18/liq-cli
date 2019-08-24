const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const expectedUsage = new RegExp(`Usage`)

test('no argument results in usage and error', () => {
  console.error = jest.fn() // supresses err echo from shelljs
  const result = shell.exec(`catalyst`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`Invalid invocation. See usage above.\\s*`))

  expect(result.stdout.replace(/\033\[\d*m/g, "")).toMatch(expectedUsage)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(1)
})

test('invalid global action results in usage and error', () => {
  const badGlobal = 'no-such-global-action'
  console.error = jest.fn() // supresses err echo from shelljs
  const result = shell.exec(`catalyst ${badGlobal}`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`No such resource or group '${badGlobal}'. See usage above.\\s*`))

  expect(result.stdout).toMatch(expectedUsage)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(10)
})

test('help should print usage', () => {
  const result = shell.exec(`catalyst help`, execOpts)

  expect(result.stdout).toMatch(expectedUsage)
  expect(result.stderr).toEqual('')
  expect(result.code).toBe(0)
})
