@load base/misc/version
@load base/utils/backtrace

## ZTest is a basic unit testing framework for Zeek scripts
## It is largely based on Ruby's MiniTest framework (https://github.com/seattlerb/minitest)
## The expected use case is to combine this with BTest to create rich unit tests that provide detailed output and make it easier to understand what failed

# Todo items:
# * Hook into the input framework to easily load test datasets
# * Be able to assert that a notice was raised
module ZTest;

export {
    ## Configuration functions
    global suppress_success_output: function();
    global suppress_all_output: function();
    global hook_exit: function();

    global test: function(test_name: string, body: function());
    global run_tests: function();
    global test_suite: function(name: string);

    global assert_equal: function(expected: any, actual: any, message: string); 
    global assert: function(condition: bool, message: string);
    global assert_instance_of: function(expected: string, object: any, message: string);
    global assert_matches: function(regex: pattern, str: string, message: string);
    global assert_greater_than: function(threshold: double, actual: double, message: string);
    global assert_greater_than_or_equal: function(threshold: double, actual: double, message: string);
    global assert_less_than: function(threshold: double, actual: double, message: string);
    global assert_less_than_or_equal: function(threshold: double, actual: double, message: string);
    global assert_in_delta: function(expected: double, actual: double, delta: double, message: string);

    global retrieve_all_results: function(): table[string] of table[string] of table[string] of bool;

    global test_exit: function();

    type TestStats: record {
        succeeded: count &default=0;
        failed: count &default=0;
    };
}

## Some state variables
global tests: table[string] of function();
global current_test = "";
global results: table[string] of TestStats;
global current_test_suite = "<not defined>";
global all_test_results: table[string] of table[string] of table[string] of bool;
global has_any_test_failed = F;
global should_output_success = T;
global should_output_failures = T;
global use_test_exit_code = F;

## Instructs the test framework that it should hook the zeek_done event and exit with a test-based status code
function hook_exit() {
    use_test_exit_code = T;
}

## Don't print out any output if tests are successful
function suppress_success_output() {
    should_output_success = F;
}

## Don't print out any output (use the retrieve_all_results method to programmatically inspect results)
function suppress_all_output() {
    should_output_success = F;
    should_output_failures = F;
}

## Helper method to print success-related strings
##
## str: The string that should be printed if success-related string printing is enabled
function print_success(str: string) {
    if (should_output_success) {
        print(str);
    }
}

## Helper method to print failure-related strings
##
## str: The string that should be printed if failure-related string printing is enabled
function print_failure(str: string) {
    if (should_output_failures) {
        print(str);
    }
}

function print_failure_backtrace() {
@if (Version::at_least("3.2.0"))
    if (should_output_failures) {
        print("Backtrace: ");
        print_backtrace(T);
    }
@endif
}
    
## Retrieves all test results so far. The output format is a table of the format:
## "suite_name" : {
##   "test_name" : {
##       "assertion_message" : T/F (true if passed, false if failed)
##   }
## }
##
## Returns: A table where the key is the name of the test suite and the value is another table where the key 
## is the name of the test and the value is another table where the key is the name of the assertion and the
## value is T if the assertion passed and F otherwise
function retrieve_all_results(): table[string] of table[string] of table[string] of bool {
    return all_test_results;
}
    
## Call this method to set the current test suite name. This should be called at the top of every unit test file or when switching suites. 
## If the tests for the previous suite haven't been run, it'll run them
##
## name: The name of the test suite to use
function test_suite(name: string) {
    if (|tests| > 0) {
        run_tests();
    }
    current_test_suite = name;
}

# Internal helper to manage the statistics and print out failure messages
#
# succeeded: T if the result is a success and F if it is a failure
#
# expected_string: A string representation of what was expected
#
# actual_string: A string representation of what actualy happened
#
# message: The message to present to the user when the result was a failure
function mark_result(succeeded: bool, expected_string: string, actual_string: string, message: string) {
    if (current_test !in results) {
        results[current_test] = TestStats();
    }
    if (succeeded) {
        results[current_test]$succeeded+= 1;
    } else {
        print_failure("");
        print_failure("Assert Failed: " + message + " (" + current_test_suite + "/" + current_test + ")");
        print_failure("Expected: " + expected_string);
        print_failure("Actual: " + actual_string);
        print_failure_backtrace();
        results[current_test]$failed += 1;
    }

    # Update the global variable with test results as well
    if (current_test !in all_test_results[current_test_suite]) {
        local empty_table: table[string] of bool;
        all_test_results[current_test_suite][current_test] = empty_table;
    }
    all_test_results[current_test_suite][current_test][message] = succeeded;
}

## Asserts that two things are equal to each other
## NOTE: this is done by converting both elements to a string using `cat`
## Because of this, we can't compare integers to counts or other numeric types unless they are the same type already
# TODO sometimes things like sets and tables don't actually end up being represented internally in the exact same order. Need to likely write a BIF (which I really don't want to do) to compare them
##
## expected: The expected value
##
## actual: The actual value observed
##
## message: The message to present if the assertion fails
function assert_equal(expected: any, actual: any, message: string) {
    mark_result(cat(expected) == cat(actual), cat(expected), cat(actual), message);
}

## Generic boolean assert
##
## condition: A boolean condition where T is success and F is failure
##
## message: The message to present if the assertion fails
function assert(condition: bool, message: string) {
    mark_result(condition, "condition to be true", "condition was false", message);
}

## Asserts that an object is of a given type. Note that the expected type is a string!
# TODO: support just specifying the container types without types on them (record, vector, set, table)
##
## expected: The expected instance type (as a string, all lowercase, e.g: string, int, count, etc.)
##
## object: The object whose type to check
##
## message: The message to present if the assertion fails
function assert_instance_of(expected: string, object: any, message: string) {
    mark_result(expected == type_name(object), expected, type_name(object), message);
}

## Asserts that a string matches a given regex. This is a non-anchored match (so there is an implicit ^? at the beginning of the pattern and a $? at the end)
##
## regex: The regex to test
## 
## str: The string to test against the regex
##
## message: The message to present if the assertion fails
function assert_matches(regex: pattern, str: string, message: string) {
    mark_result(regex in str, fmt("'%s' to match pattern %s", str, cat(regex)), "Didn't match pattern", message);
}

## Asserts that a value is greater than a threshold
##
## threshold: The value that the observed value should be greater than
##
## actual: The observed value
##
## message: The message to present if the assertion fails
function assert_greater_than(threshold: double, actual: double, message: string) {
    mark_result(actual > threshold, cat(actual) + " to be greater than " + cat(threshold), "Was less than or equal to", message);
}

## Asserts that a value is greater than or equal to a threshold
##
## threshold: The value that the observed value should be greater than or equal to
##
## actual: The observed value
##
## message: The message to present if the assertion fails
function assert_greater_than_or_equal(threshold: double, actual: double, message: string) {
    mark_result(actual >= threshold, cat(actual) + " to be greater than or equal to " + cat(threshold), "Was less than", message);
}

## Asserts that a value is less than a threshold
##
## threshold: The value that the observed value should be less than
##
## actual: The observed value
##
## message: The message to present if the assertion fails
function assert_less_than(threshold: double, actual: double, message: string) {
    mark_result(actual < threshold, cat(actual) + " to be less than " + cat(threshold), "Was greater than or equal to", message);
}

## Asserts that a value is less than or equal to a threshold
##
## threshold: The value that the observed value should be less than or equal to
##
## actual: The observed value
##
## message: The message to present if the assertion fails
function assert_less_than_or_equal(threshold: double, actual: double, message: string) {
    mark_result(actual <= threshold, cat(actual) + " to be less than or equal to " + cat(threshold), "Was greater than", message);
}

## Asserts that a value is within a certain delta of a threshold
## This assertion will add a small value to the delta to account for floating point errors
##
## expected: The expected value
##
## actual: The observed value
##
## delta: The amount of difference the actual value can be +/- in relation to the expected value
##
## message: The message to present if the assertion fail
function assert_in_delta(expected: double, actual: double, delta: double, message: string) {
    local wiggle_room = 0.0000000000000001; # Account for floating point errors
    mark_result(|expected - actual| <= delta + wiggle_room, cat(actual) + " to be within " + fmt("%f", delta) + " of " + cat(expected), fmt("Actual delta of %6f", |expected - actual|), message);
}

# TODO would be nice to have tests if something handles or raises events

## This is the wrapper for actual test cases. You specify the test name and then provide an anonymous function that contains your assertions
##
## test_name: The name of this test case
##
## body: An anonymous function that will contain the assertions relating to this test case
function test(test_name: string, body: function()) {
    tests[test_name] = body;
}

# Internal helper to setup the all_test_results variable for the current test suite
function initialize_all_test_result_entry() {
    local empty_table: table[string] of table[string] of bool;
    all_test_results[current_test_suite] = empty_table;
}

## Runs the currently loaded tests. Expected to be called at the end of each test file and/or test suite
## Note: This will delete the tests as it runs to support multiple test suites across multiple files
function run_tests() {
    initialize_all_test_result_entry();
    print_success("");
    print_success("Running Test Suite: " + current_test_suite);
    print_success("------------------------------------");
    for (i in tests) {
        current_test = i;
        print_success("Running Test: " + i);
        tests[i]();
        print_success("");
    }

    clear_table(tests);

    local total_succeeds = 0;
    local total_failures = 0;
    for (i in results) {
        total_succeeds += results[i]$succeeded;
        total_failures += results[i]$failed;
    }

    clear_table(results);

    if (total_failures > 0) {
        has_any_test_failed = T;
    }

    print_success("Total Assertions: " + cat(total_succeeds + total_failures));
    print_success("    " + cat(total_succeeds) + " successful assertions");
    print_success("    " + cat(total_failures) + " failed assertions");

    current_test_suite = "<not defined>";
}

# Hook the zeek_done event so we can exit with a test-related status code if we are supposed to
# Note: there's a bug currently relating to coverage when tests are run at Zeek exit (zeek_done). The coverage runs before this event is called.
event zeek_done() &priority=1000000 {
    # If we haven't run the tests, run them now
    if (|tests| > 0) {
        run_tests();
    }

    if (use_test_exit_code) {
        test_exit();
    }
}

## Exits Zeek with the proper exit code if a test failed (0 if no tests failed, 1 if any failed)
function test_exit() {
    print_success("Exiting with test exit code");
    exit(has_any_test_failed ? 1 : 0);
}
