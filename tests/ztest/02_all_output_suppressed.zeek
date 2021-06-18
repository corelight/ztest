# @TEST-EXEC: zeek %INPUT &> output
# @TEST-EXEC: btest-diff output

@load ztest

ZTest::suppress_all_output();

ZTest::test_suite("Suite 1");

ZTest::test("Example Test 1", function() {
    ZTest::assert_equal(1, 1, "1 didn't equal 2");
});

ZTest::test("Example Test", function() {
    ZTest::assert_equal(1, 2, "1 didn't equal 2");
});

ZTest::run_tests();
