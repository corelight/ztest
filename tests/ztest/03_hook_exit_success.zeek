# @TEST-EXEC: zeek -b %INPUT &> output
# @TEST-EXEC: btest-diff output

@load ztest

ZTest::test_suite("Suite 1");

ZTest::test("Example Test", function() {
    ZTest::assert_equal(1, 1, "1 didn't equal 2");
});

ZTest::run_tests();
