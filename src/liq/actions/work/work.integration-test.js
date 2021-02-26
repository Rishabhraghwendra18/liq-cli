// These tests are designed to be run sequentially and are kicked off by
// 'seqtests.test.js'.
import { testCheckoutDir } from '../project/project.integration-test.js'
const shell = require('shelljs')

const execOpts = {
  shell: shell.which('bash'),
  silent: true,
}

const expectedWorkUsage = expect.stringMatching(new RegExp(`Valid work actions are:\\s+`))

describe('liq work', () => {
  // afterAll(() => shell.exit(0))

  test('no action results in error and work help', () => {
    console.error = jest.fn() // supresses err echo from shelljs
    const result = shell.exec(`${testing.LIQ} work`, execOpts)
    const expectedErr = expect.stringMatching(
      new RegExp(`No action argument provided.\\s*`))

    expect(result.stderr).toEqual(expectedErr)
    expect(result.stdout).toEqual(expectedWorkUsage)
    expect(result.code).toBe(1)
  })

  test("'help work' prints work help", () => {
    const result = shell.exec(`${testing.LIQ} help work`, execOpts)

    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual(expectedWorkUsage)
    expect(result.code).toBe(0)
  })

  test("'work start' should require additional arguments", () => {
    const result = shell.exec(`cd ${testCheckoutDir} && ${testing.LIQ} work start`, execOpts)
    const expectedErr = expect.stringMatching(
      new RegExp(`'work start' requires 1 additional arguments.`))

    expect(result.stderr).toEqual(expectedErr)
    expect(result.stdout).toEqual('')
    expect(result.code).toEqual(1)
  })

  test("'work start add-feature' result in new branch", () => {
    const result = shell.exec(`cd ${testCheckoutDir} && ${testing.LIQ} work start add-feature`)
    const expectedOutput = expect.stringMatching(new RegExp(`^Now working on branch '\\d{4}-\\d{2}-\\d{2}-[^-]+-add-feature'.[\\s\\n]*$`))

    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual(expectedOutput)
    expect(result.code).toEqual(0)

    const branchCheck = shell.exec(`cd ${testCheckoutDir} && git branch | wc -l | awk '{print $1}'`)
    expect(branchCheck.stderr).toEqual('')
    expect(branchCheck.stdout).toEqual("2\n")
    expect(branchCheck.code).toEqual(0)
  })

  test("'work merge' results merge, push, and deleting branch", () => {
    shell.exec(`echo "hey" > ${testCheckoutDir}/foo.txt`)
    shell.exec(`cd ${testCheckoutDir} && git add foo.txt && git commit -m 'test file'`)
    const result = shell.exec(`cd ${testCheckoutDir} && ${testing.LIQ} work merge`)
    // TODO: test the linecount
    const expectedOutput = expect.stringMatching(new RegExp(`^Work merged and pushed to remotes.`))

    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual(expectedOutput)
    expect(result.code).toEqual(0)

    const branchCheck = shell.exec(`cd ${testCheckoutDir} && git branch | wc -l | awk '{print $1}'`)
    expect(branchCheck.stderr).toEqual('')
    expect(branchCheck.stdout).toEqual("1\n")
    expect(branchCheck.code).toEqual(0)
  })
})
