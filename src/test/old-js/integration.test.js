import * as testing from './lib/testing'
import './actions/meta/init.integration-test.js'
import './actions/projects/import.integration-test.js'
import './actions/projects/close.integration-test.js'
// import './actions/work/work.integration-test.js'

beforeAll(testing.setupLocalRepos)
afterAll(testing.cleanupLocalRepos)
