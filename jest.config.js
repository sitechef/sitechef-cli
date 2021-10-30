module.exports = {
	moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
  roots: ['<rootDir>/src'],
        setupFilesAfterEnv: [
                '<rootDir>/jest.setup.js',
        ],
  transform: { '^.+\\.tsx?$': 'ts-jest' },
  testEnvironment: 'node',
  testMatch: ['**/*.test.ts'],
}