@load ztest.zeek

ZTest::suppress_success_output();

#ZTest::hook_exit();
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

ZTest::run_tests();