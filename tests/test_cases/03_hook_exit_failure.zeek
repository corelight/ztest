@load ../../scripts/ztest.zeek

ZTest::hook_exit();

ZTest::test_suite("Suite 1");

ZTest::test("Example Test", function() {
    ZTest::assert_equal(1, 2, "1 didn't equal 2");
});

ZTest::run_tests();