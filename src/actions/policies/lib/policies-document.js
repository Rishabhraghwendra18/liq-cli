import { Policies, Roles } from '@liquid-labs/policies-model'

const refreshDocuments = (destDir, inputFiles) => {
  const policies = new Policies()
  inputFiles.forEach((f) => policies.addSourceFile(f))
  policies.setDocumentDir(destDir)
  policies.generateDocuments()
}

export { refreshDocuments }
