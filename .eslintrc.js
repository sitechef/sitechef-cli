
// eslint-disable-next-line no-undef
module.exports = {
  env: {
    browser: true,
    es2021: true,
    jest: true,
	},
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/eslint-recommended',
		'plugin:@typescript-eslint/recommended',
		'prettier'
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
	rules: {
		'@typescript-eslint/no-explicit-any': "off",
		'@typescript-eslint/no-unused-vars': [
			"warn",
			{
				"varsIgnorePattern": "_.*",
				"argsIgnorePattern": "_.*"
			}
		]
	}
};