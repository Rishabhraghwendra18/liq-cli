const shell = require('shelljs')

export const selfOriginUrl = 'https://github.com/Liquid-Labs/catalyst-cli.git'

export const expectedCommandGroupUsage = (group) => new RegExp(`catalyst .*${group}.* <action>:`)

export const setup = () => {
  const randomHex = Math.floor((1 + Math.random()) * 0x1000000000000)
    .toString(16)
    .substring(1)

  // I'd likue to do this, but it gives weird results on Mac Mojave
  // const tmpDir = shell.tempdir()
  const tmpDir = `/tmp`
  const testHome = `${tmpDir}/liq-cli-test-${randomHex}`
  const testPlayground = `${testHome}/playground`
  const testOriginDir = `${testHome}/git-origin`
  const testCheckoutDir = `${testPlayground}/test-checkout`
  const testProjectDir = `${testPlayground}/catalyst-cli`

  shell.mkdir('-p', testHome)

  return {
    testHome,
    testPlayground,
    testOriginDir,
    testCheckoutDir,
    testProjectDir,
    // TODO: don't cleanup if errors? (and mention the fact)
    cleanup: () => { [testHome].forEach(dir => shell.rm('-rf', dir)) }
  }
}
