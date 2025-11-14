module.exports = {
  extends: ['expo', 'prettier'],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  env: {
    node: true,
    es2020: true,
  },
  ignorePatterns: ['build/', 'node_modules/', 'example/'],
  rules: {
    // Let Prettier handle formatting
    // Add project-specific rules here if needed
  },
};
