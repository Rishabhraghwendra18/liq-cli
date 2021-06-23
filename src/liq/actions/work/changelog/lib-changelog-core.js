import * as fs from 'fs'

const readChangelog = () => {
  const clPath = requireEnv('CHANGELOG_FILE')

  const changelogContents = fs.readFileSync(clPath)
  const changelog = JSON.parse(changelogContents)

  return changelog
}

const requireEnv = (key) => {
  return process.env[key] || throw new Error(`Did not find required environment parameter: ${key}`)
}

const saveChangelog = (changelog) => {
  const clPath = requireEnv('CHANGELOG_FILE')

  const changelogContents = JSON.stringify(changelog, null, 2)
  fs.writeFileSync(clPath, changelogContents)
}

export {
  readChangelog,
  requireEnv,
  saveChangelog
}
