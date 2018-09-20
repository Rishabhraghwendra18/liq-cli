const shell = require('shelljs')

export const randomHex = Math.floor((1 + Math.random()) * 0x1000000000000)
  .toString(16)
  .substring(1)

export const selfOriginUrl = 'https://github.com/Liquid-Labs/catalyst-cli.git'

// TODO: don't cleanup if errors? (and mention the fact)
export const cleanupDirs = (...dirs) => () =>
  dirs.forEach(dir => shell.rm('-rf', dir))
