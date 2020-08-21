# ZTest
ZTest - Zeek Unit Testing. Provides a framework to write unit tests for Zeek scripts.

## Background and Example
ZTest is intended to be used alongside of your Zeek scripts to make your unit testing easy, fast, and more idiomatic. It an be combined with BTest as by default ZTest provides a rich output that clearly annotates test failures. This makes it easy to identify what failed in a BTest diff, for example. The basic structure of a ZTest file is as follows:

```zeek
@load ztest.zeek

ZTest::test_suite("Suite 1");

ZTest::test("Example Test", function() {
    ZTest::assert_equal(2, 1, "1 didn't equal 2");
});

ZTest::test("Another Example Test", function() {
    ZTest::assert_equal("hi", "hi", "Strings didn't match");
    ZTest::assert_instance_of("count", "Hi There", "Instance of didn't work");
    ZTest::assert_matches(/foo|bar/, "hi there", "Didn't match when should have");
    ZTest::assert_greater_than(+15, +11, "Greater than check failed");
});
```

This will output the following (by default):
```
Running Test Suite: Suite 1
------------------------------------
Running Test: Example Test

Assert Failed: 1 didn't equal 2
Expected: 2
Actual: 1

Running Test: Another Example Test

Assert Failed: Instance of didn't work
Expected: count
Actual: string

Assert Failed: Didn't match when should have
Expected: 'hi there' to match pattern /^?(foo|bar)$?/
Actual: Didn't match pattern

Assert Failed: Greater than check failed
Expected: 11.0 to be greater than 15.0
Actual: Was less than or equal to

Total Assertions: 5
    1 successful assertions
    4 failed assertions
```

## General Test Structure
Tests are generally separated into different files for each test suite (but this is not a requirement). If you have more than one test file, it is recommended you also include a overall testing file that loads all of the tests so that they can be run altogether. Otherwise, you will have to invoke each file separately using zeek when you want to test particular parts of your codebase. 

Inside of each test file, you use the `ZTest::test_suite(name: string)` method to let ZTest know that you are writing tests for a given suite. This helps you interpet the output, especially if you have many ZTest suites/files. If you don't specify a name, the name will be `<not defined>`. After the test suite name declaration, You write individual test cases by using the `ZTest::test_case(name: string, body: function)` method. This method takes an anonymous function that encapsulates your various test logic and your assert statements. When the tests are run, this anonymous function is executed and the results of the asserts can then be associated with the name of the test case. 

Inside of a test_case (and technically outside of one too if you want), there are a number of assertions provided by the framework. These generally take the form of `assertion(expected, actual, failure_message)`

* `assert`: A generic boolean assertion
* `assert_equal`: Check that an actual value matches the expected value
* `assert_instance_of`: Checks that the provided value is of a given Zeek variable type
* `assert_matches`: Checks that a string matches a given regular expression
* `assert_greater_than`: Checks that a number is greater than an expected threshold
* `assert_greater_than_or_equal`: Checks that a number is greater than or equal to an expected threshold
* `assert_less_than`: Checks that a number is less than an expected threshold
* `assert_less_than_or_equal`: Checks that a number is less than or equal to an expected threshold
* `assert_in_delta`: Checks that a number is within some delta value of a given threshold

The assertions will automatically keep track of what test case they belong to and whether they succeeded or failed. 

*NOTE*: Unlike some other test frameworks, ZTest will not end the testing when it encounters a failed assertion. This means that you shouldn't assume all assertions above the current one passed when you are writing your code.

## Running The Tests
ZTest doesn't execute tests as soon as they are added using the `test` method. Instead, it waits for you to invoke them using the `ZTest::run_tests()` method. This is expected to be done at the end of each test suite. Once the tests have been run, the results are written to STDOUT (if enabled) and the current test suite is reset to an empty one. If you don't run the tests, ZTest will run them when zeek_exit() occurs.

## Configuration Options and Special Methods
ZTest is designed to be used in a wide variety of manners, and as such has a few configuration options that you can use. These options are usually specified through calling functions that tell ZTest that you want to modify a configuration option. The methods are as follows:

* `ZTest::suppress_success_output()`: Tells ZTest that it shouldn't write anything to STDOUT unless a test failed. This is a great method to call if you want to use ZTest with BTest since you can always add test cases without changing your benchmark (the benchmark becomes an empty STDOUT). If a test fails, it'll write to STDOUT and your BTest will fail since the benchmark is empty and the output won't be
* `ZTest::suppress_all_output()`: Tells ZTest to not write anything to STDOUT (successes or failures). This is helpful if you want to do some custom work with the ZTest output (see `ZTest::retrieve_all_results`)
* `ZTest::hook_exit()`: Tells ZTest to hook the `zeek_done` event and to alter the Zeek exit code based on the test results. If there were no failed tests, the exit code will be `0` and if there were any failed tests it will be `1`

Special methods for interfacing with the ZTest framework are:

* `ZTest::retrieve_all_results()`: Returns a Zeek table with all of the current results (for tests that have been run). The keys of the table are the names of the test suites and the values are another table with the key being each test name in that suite with the value being another table with the key being each assertion name and the value being T if the assertion passed and F if it did not:
```
{
        [Suite 1] = {
                [Another Test] = {
                        [More examples] = T
                },
                [Example Test] = {
                        [Should fail] = F,
                        [1 didn't equal 1] = T
                }
        },
        [Suite 3] = {
                [Test me] = {
                        [Empty String] = T
                }
        }
}
```
* `ZTest::test_exit()`: Exits Zeek, setting the exit code to 0 if no tests failed and 1 if any test failed. This can be used to manually exit as opposed to enabling the auto exit hook with `ZTest::hook_exit()`

## Testing an Event-Driven System
Zeek is by its nature very event-driven. This can seemingly make unit testing much harder to do since a lot of work is done inside of event handlers. For example, given the following code:

```zeek
event my_event(param1: string, param2: string) {
    if (param1 == "hi" && param2 == "there") {
        # Do something, maybe log a notice
    }
}
```

At the surface, unit testing this seems very difficult. The reality is that good testing starts with code architecture. If we move our logic around we can now easily test it:

```zeek
function should_notice(param1: string, param2: string): bool {
    return param1 == "hi" && param2 == "there";
}

event my_event(param1: string, param2: string) {
    if (should_notice(param1, param2)) {
        # Do something, maybe log a notice
    }
}
```

We can now test the `should_notice` function without having to worry about the event or logging parts of Zeek. This same pattern can (and should!) be used whenever possible to enable unit testing and to make more reusable code.

## Installation
### With Zeek Package Manager - Automatic
`zkg install corelight/ztest`
### With Zeek Package Manager - Manual Download
```bash
git clone https://github.com/corelight/ztest
cd ztest
zkg install .
```

## Closing Thoughts
This framework was designed to better enable Zeek script developers to test their code. There are some things to consider with it, however:

* Equality checks are executed by using the `cat` method internally. This means that for some container types (records, sets, and tables), the ordering of the elements in the container isn't always perfect internally in Zeek. This means that equality comparisons for those types aren't 100% accurate. If there are particular things you want to check, it is recommended you do so with more detailed inspection of the containers being compared
* Events aren't handled or managed with ZTest. This means that you can't check if an event was raised or handled (yet). This is a future desired feature but something to remember
* Test cases are inside of anonymous functions. Take care with scoping and closures

### Future Ideas/Plans/Wish list:
* Event-aware assertions such as `assert_raises(event)` or `assert_handles(event)`
* Logging or Notice framework aware assertions such as `assert_generates_notice` or `assert_logs`
* Broker aware assertions (publishing to topic, etc.)

## Running the ZTest Framework Tests
ZTest comes with unit tests for itself. These are a set of Zeek scripts that exercise the functionality of the framework. The unit tests are run using a Ruby driver. Ruby is only used to unit test ZTest, and isn't a requirement for using ZTest otherwise. To run the tests:
```bash
cd tests
ruby test_ztest.rb
```