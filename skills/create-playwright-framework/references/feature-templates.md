# Feature file templates

Generic templates for E2E and validation scenarios. Replace every `<placeholder>` with values verified from the target service. Do not invent page names, messages or field labels. Bind all steps in `e2e-tests/steps/` and discover both features (see the starter patterns).

## 1. E2E journey template

**Target file:** `e2e-tests/features/<service>.feature`

```gherkin
@<Service>RegressionTest
Feature: <Service> - <user goal>

  @<Service>E2ETest
  Scenario Outline: <User> completes the <journey> E2E test
    Given I visit the <service start> page
    When I fill out the answers to the <service> form pertaining to "<Journey>"
    Then I am navigated to "<final confirmation page>" page
    Examples:
      | Journey                               |
      | T1: All fields completed              |
```

Notes:
- Each Examples label must have a matching lowercase `case` in the step `switch`; `default` must throw.
- Keep one Examples row so the outline runs as one E2E test.
- Do not add a submitting scenario until submission side effects are approved.

## 2. Validation template

**Target file:** `e2e-tests/features/<service>-validation.feature`

```gherkin
@<Service>RegressionTest
Feature: <Service> - validation

  # List the pages covered so reviewers can see the scope
  # <Page 1>
  # <Page 2>
  Scenario: <Service> Test-1 Validate the above pages
    Given I visit the <service start> page
    When I choose to navigate to "<Page 1>" page for <service>

    # <Page 1>: nothing entered
    And I select continue
    Then I should see "<error summary heading>" error message displayed
    And I should see "<exact required-field message>" error summary

    # <Page 1>: invalid value
    When I enter "<invalid value>" into "<field>" field and page for <service>
    Then I should see "<error summary heading>" error message displayed
    And I should see "<exact invalid-value message>" error summary

    # <Page 1>: valid value so the journey can advance
    When I enter "<valid value>" into "<field>" field and page for <service>

    # <Page 2>: nothing entered
    And I select continue
    Then I should see "<error summary heading>" error message displayed
    And I should see "<message 1>¬<message 2>" error summary
```

Notes:
- For each page: empty submit, then each invalid variant, then a valid entry to move on.
- Copy expected messages verbatim from the application; messages joined by `¬` are one multi-error summary and must match the step's split character.
- Implement navigation and field-entry steps for the verified service, including submission after field entry; reuse the shared Given, continue and error bindings.
- Keep one page's invalid cases together, ending with valid data so later pages stay reachable.
- Keep all validation checks in this single scenario.
