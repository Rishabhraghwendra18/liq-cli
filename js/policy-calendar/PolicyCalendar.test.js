import { PolicyCalendar } from './PolicyCalendar'

describe(`PolicyCalendar`, () => {
	let testPolicyCalendar
	beforeAll(() => {
		testPolicyCalendar = new PolicyCalendar(`./js/policy-calendar/test_data.tsv`)
	})

	test('parses test file', () => expect(testPolicyCalendar).toBeTruthy())
	test('ignore blank lines', () => expect(testPolicyCalendar.length).toBe(4))
	test(`properly sets fields`, () => {
		testPolicyCalendar.reset()
		const item = testPolicyCalendar.next()
		expect(item['itemName']).toBe('Annual thing.')
	})
})
