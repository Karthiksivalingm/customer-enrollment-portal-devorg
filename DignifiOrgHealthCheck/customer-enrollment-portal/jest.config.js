const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
  // Jest cannot resolve CSS-only LWC modules on its own; point it at the file.
  moduleNameMapper: {
    ...(jestConfig.moduleNameMapper || {}),
    "^c/enrollmentStyles$":
      "<rootDir>/force-app/main/default/lwc/enrollmentStyles/enrollmentStyles.css"
  }
};
