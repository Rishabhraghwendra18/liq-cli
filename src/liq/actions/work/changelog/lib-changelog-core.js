import * as fs from 'fs'
import YAML from 'yaml'

const readChangelog = () => {
  const clPathish = requireEnv('CHANGELOG_FILE')
  const clPath = clPathish === '-' ? 0 : clPathish

  const changelogContents = fs.readFileSync(clPath, 'utf8') // include encoding to get 'string' result
  const changelog = YAML.parse(changelogContents)

  return changelog
}

const requireEnv = (key) => {
  return process.env[key] || throw new Error(`Did not find required environment parameter: ${key}`)
}

const saveChangelog = (changelog) => {
  const clPath = requireEnv('CHANGELOG_FILE')

  const changelogContents = YAML.stringify(changelog)
  fs.writeFileSync(clPath, changelogContents)
}

export {
  readChangelog,
  requireEnv,
  saveChangelog
}
