import * as testing from './lib/testing'
import './actions/meta/init.integration-test.js'
import './actions/project/import.integration-test.js'
import './actions/project/close.integration-test.js'
// import './actions/work/work.integration-test.js'

beforeAll(testing.setupLocalRepos)
afterAll(testing.cleanupLocalRepos)
