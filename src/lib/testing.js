const shell = require('shelljs')

export const selfOriginUrl = 'https://github.com/Liquid-Labs/catalyst-cli.git'

export const expectedCommandGroupUsage = (group) => new RegExp(`catalyst .*${group}.* <action>:`)

export const setup = () => {
  const randomHex = Math.floor((1 + Math.random()) * 0x1000000000000)
    .toString(16)
    .substring(1)

  const testPlayground = `/tmp/catalyst-test-playground-${testing.randomHex}`
  const testOriginDir = `/tmp/catalyst-test-gitorigin-${testing.randomHex}`
  const testCheckoutDir = `${testPlayground}/test-checkout`
  const testProjectDir = `${testPlayground}/catalyst-cli`

  return {
    testPlayground,
    testOriginDir,
    testCheckoutDir,
    testProjectDir,
    // TODO: don't cleanup if errors? (and mention the fact)
    cleanup: () => () => [testPlayground, testOriginDir].forEach(dir => shell.rm('-rf', dir))
  }
}
