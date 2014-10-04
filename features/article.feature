Feature: Single article
  As a person interested in what Amitai writes
  I want to read an article on his website
  In order to maybe learn something

  Background:
    Given the site's base URL "http://www.schmonz.com/"

  Scenario: Check article
    Given a web browser
    When I request the typical article "/2013/06/10/area-under-the-curve"
    Then the posted date is "2013-06-10"
    Then the title ends with "Area under the curve"
    Then the body contains "battle against local entropy"
