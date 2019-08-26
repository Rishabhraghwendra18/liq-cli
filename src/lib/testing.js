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
  const home = `${tmpDir}/liq-cli-test-${randomHex}`
  const testPlayground = `${home}/playground`
  const testOriginDir = `${home}/git-origin`
  const testCheckoutDir = `${testPlayground}/test-checkout`
  const testProjectDir = `${testPlayground}/catalyst-cli`

  shell.mkdir('-p', home)

  return {
    home,
    testPlayground,
    testOriginDir,
    testCheckoutDir,
    testProjectDir,
    // TODO: don't cleanup if errors? (and mention the fact)
    cleanup: () => { [home].forEach(dir => shell.rm('-rf', dir)) }
  }
}
