import * as testing from './testing'

const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const expectedUsage = new RegExp(`Usage`)

describe(`Command 'catalyst'`, () => {
  test('with no arguments results in help and error.', () => {
    console.error = jest.fn() // supresses err echo from shelljs
    const result = shell.exec(`catalyst`, execOpts)
    const expectedErr = expect.stringMatching(
      new RegExp(`Invalid invocation. See help above.\\s*`))

    expect(result.stdout.replace(/\033\[\d*m/g, "")).toMatch(expectedUsage)
    expect(result.stderr).toEqual(expectedErr)
    expect(result.code).toBe(1)
  })

  test('with invalid global action results in help and error', () => {
    const badGlobal = 'no-such-global-action'
    console.error = jest.fn() // supresses err echo from shelljs
    const result = shell.exec(`catalyst ${badGlobal}`, execOpts)
    const expectedErr = expect.stringMatching(
      new RegExp(`No such resource or group '${badGlobal}'. See help above.\\s*`))

    expect(result.stdout).toMatch(expectedUsage)
    expect(result.stderr).toEqual(expectedErr)
    expect(result.code).toBe(10)
  })
})

describe(`Command 'catalyst' help`, () => {
  // TODO: let's make summary the default and '--full' the option
  test('with no args or opts should print help', () => {
    const result = shell.exec(`catalyst help`, execOpts)

    expect(result.stdout).toMatch(expectedUsage)
    expect(result.stderr).toEqual('')
    expect(result.code).toBe(0)
  })

  test("with 'project' prints project help", () => {
    const result = shell.exec(`catalyst help project`, execOpts)

    expect(result.stderr).toEqual('')
    expect(result.stdout).toMatch(testing.expectedCommandGroupUsage(`project`))
    expect(result.code).toBe(0)
  })
})
