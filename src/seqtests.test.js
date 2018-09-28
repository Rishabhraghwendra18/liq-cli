// The project and work tests are designed to be run sequentially (hence
// 'seqtest') in order to avoid creataing a workspace and dir for each test.
// It may be worthwhile to re-engineer everything to make quick copies of a
// template or something, but for now, this seems the most sensible approach
// since there is a sequential nature to much of the setup and use of a
// workspace and project.
import { testWorkspaceDir, testOriginDir } from './actions/project/project.seqtest.js'
import './actions/work/work.seqtest.js'
import * as testing from './lib/testing'

// afterAll(testing.cleanupDirs(testWorkspaceDir, testOriginDir))
