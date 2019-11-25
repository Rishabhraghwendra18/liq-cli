import { Staff } from './Staff'

describe(`Staff`, () => {
	let testStaff
	beforeAll(() => {
		testStaff = new Staff(`./js/staff/test_data.tsv`)
	})

	test('parses test file', () => expect(testStaff).toBeTruthy())
	test('ignore blank lines', () => expect(testStaff.length).toBe(1))
	test(`properly sets fields`, () => {
		testStaff.reset()
		const staff = testStaff.next()
		expect(staff['email']).toBe('foo@bar.com')
	})
})
