const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

test('invalid global action results in error', () => {
  const badGlobal = 'no-such-global-action'
  const result = shell.exec(`gcproj ${badGlobal}`, execOpts)
  const expectedErr = expect.stringMatching(
    new RegExp(`No such component or global action '${badGlobal}'.\\s*`))

  expect(result.stdout).toBe('')
  expect(result.stderr).toEqual(expectedErr)
  expect(result.code).toBe(1)
})
