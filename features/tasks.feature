Feature: Tasks
  In order to keep things organised
  As an organised person
  I want to manage my tasks

  Scenario: Empty Listing of Tasks
    Given I am on home page
    Then I should see "My Tasks" within "main heading"
    And I should see no tasks

  @javascript
  Scenario: Create a Task
    Given I am on home page
    When I press "Add Task"
    Then I should see "Please try again"
    When I fill in "task[title]" with "Learn Cucumber"
    And I press "Add Task"
    Then I should not see "Please try again"
    And I should see "Learn Cucumber" within "tasks list"
    When I go to home page
    Then I should see "Learn Cucumber" within "tasks list"