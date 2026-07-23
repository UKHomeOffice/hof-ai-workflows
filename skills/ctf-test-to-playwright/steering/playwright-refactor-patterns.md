## The target implementation must follow the architecture, design patterns, coding standards, folder structure, naming conventions, and Page Object Model implementation used in the "lmr e2e-tests" project.

## Implementation Requirements
## Project Structure
-	Use the "lmr e2e-tests" project as the source of truth for framework implementation.
-	Create a new folder called "e2e-tests" in 'end-tenancy' folder.
-	Replicate the structure, patterns, fixtures, utilities, helpers, and conventions used within lmr e2e-tests.
-	Generate all required files, folders, page objects, feature files, step definitions, fixtures, helpers, constants, and test data classes.
-	Ensure all generated files follow consistent naming standards and match the functionality they represent.

## Feature Files: Fully implement every scenario from the features 
## Requirements:
-	Preserve all business logic.
-	Preserve all acceptance criteria.
-	Preserve all validations.
-	Do not omit any scenarios.
-	Maintain full feature parity with the Selenium implementation.

## Test Data Conversion if one exist all data from:
## Requirements:
-	Remove CSV dependency.
-	Replace CSV-driven data with TypeScript switch-case based data management.
-	Preserve all existing test data and business rules.
-	Ensure test data remains easy to maintain and extend.

## Page Object Model: Convert all Selenium Page Objects into Playwright Page Objects.
## Requirements:
-	Follow the exact POM structure used in lmr e2e-tests.
-	Create all missing pages required for the UkViet journey.
-	Ensure file names match page names.
-	Encapsulate all page interactions within page classes.
-	Refactor common actions into reusable components or helper methods.
-	Keep selectors and actions separated from test logic.
-	Review all pages and identify any hardcoded test data.
-	Create a constants-lib.ts file within the utility-helper folder.
-	Centralise all test data values in the constants file, following the implementation used in LMR as a reference.
-	Update the relevant .step.ts files to consume values from constants-lib.ts.
-	Do not introduce test data dependencies into the page objects. Keep page objects generic.
-   ensure all test data handling remains within the step layer consistent with the LMR approach.

## Selenium to Playwright Migration Rules:
-	Use Playwright Test Framework (@playwright/test).
-	Convert JUnit/TestNG annotations into Playwright constructs.
-	Convert WebDriver interactions into Playwright APIs.
-	Use async/await throughout.
-	Use strict TypeScript typing.
-	Replace Selenium waits with Playwright auto-waiting.
-	Remove Thread.sleep().
-	Remove WebDriverWait.
-	Remove ExpectedConditions.
-	Replace Selenium assertions with Playwright expect assertions.
-	Replace Selenium Actions with Playwright equivalents.
-	Replace frame handling with frameLocator().
-	Replace alert handling with Playwright dialog handling.
-	Replace tab/window handling with Playwright context/page APIs.
-	Replace JavascriptExecutor usage with Playwright-native APIs wherever possible.
-   Ensure that expected page title method is implemented for each pages

## Locator Strategy 
## Prioritize:
1. getByRole()
2. getByLabel()
3. getByText()
4. locator()
## Avoid XPath unless there is no practical alternative.


## Code Quality Standards
-	Use latest TypeScript syntax.
-	Apply Playwright best practices.
-	Follow SOLID principles.
-	Follow clean code principles.
-	Eliminate duplicated logic.
-	Centralize reusable functionality.
-	Ensure the code is production-ready and maintainable.
-	Add concise comments only where migration decisions require explanation.


## Validation Checklist
## Before generating code:
-	Analyse the Selenium Java implementation.
-	Identify all page objects.
-	Identify all feature files.
-	Identify all step definitions.
-	Identify all utilities and framework components.
-	Identify all test data sources.
-	Identify reusable workflows.
-	Map Selenium APIs to Playwright equivalents.
-	Identify any Selenium functionality that does not have a direct Playwright equivalent.


## For unsupported Selenium functionality:
-	Implement the recommended Playwright alternative.
-	Document the migration decision.


## Output Requirements
## Generate:
1. Complete Playwright TypeScript implementation.
2. All Page Objects.
3. All Feature Files.
4. All Step Definitions.
5. Fixtures and Helpers.
6. Switch-case based test data implementation.
7. Supporting utilities and components.
8. Migration summary.

## Critical Rules
-	Do not skip any scenario.
-	Do not use placeholders or TODO comments.
-	Do not provide partial implementations.
-	Ensure all code compiles and is executable.
-	Preserve all original business behaviour and validations.
-	Follow the ‘lmr e2e-tests’ framework structure exactly.
-	Produce implementation-ready code.
-	Return generated files grouped by folder structure, followed by a concise migration summary.
