Feature: Pages
  As a person interested in what Amitai writes
  I want to browse his website
  In order to maybe learn something

  Background:
    Given Amitai's production website

  Scenario: Check single article
    Given a browser
    When I request a single article
    Then it has the sidebar
    Then its title matches the slug
    Then it has exactly one wordcount
    Then its posted date matches the slug
    Then its body content is there

  Scenario: Check index page
    Given a browser
    When I request the main index page
    Then it has the sidebar
    Then its title matches the site title
    Then it has five wordcounts
    Then it has five article titles
    Then it has five posted dates
    # Then it has five body contents
