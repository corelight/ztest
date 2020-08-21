@load ../../scripts/ztest.zeek

ZTest::suppress_all_output();

ZTest::test_suite("Suite 1");

ZTest::test("Example Test", function() {
    ZTest::assert_equal(1, 1, "1 didn't equal 1");
    ZTest::assert_equal(1, 2, "Should fail");
});

ZTest::test("Another Test", function () {
    ZTest::assert_equal(1, 1, "More examples");
});

ZTest::run_tests();

ZTest::test_suite("Suite 3");

ZTest::test("Test me", function () {
    ZTest::assert_equal("", "", "Empty String");
});

ZTest::run_tests();

local results = ZTest::retrieve_all_results();

print(cat(results["Suite 1"]["Example Test"]["1 didn't equal 1"]));
print(cat(results["Suite 1"]["Example Test"]["Should fail"]));
print(cat(results["Suite 1"]["Another Test"]["More examples"]));
print(cat(results["Suite 3"]["Test me"]["Empty String"]));

print("Made it to the end without any invalid table key errors!");
