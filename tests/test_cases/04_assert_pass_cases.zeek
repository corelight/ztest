@load ../../scripts/ztest.zeek

module TestSuite;
export {
    type color: enum {Red, White, Blue};
    type MyRecordType: record {
        c: count;
        s: string;
    };
}

ZTest::test_suite("Suite 1");

ZTest::test("Assert Equal Tests", function() {
    ZTest::assert_equal(1, 1, "1 didn't equal 1");
    ZTest::assert_equal(1.0, 1.0, "didn't equal when should have");
    ZTest::assert_equal(+1, +1, "didn't equal when should have");
    ZTest::assert_equal("hi", "hi", "didn't equal when should have");
    ZTest::assert_equal(1.2.3.4, 1.2.3.4, "didn't equal when should have");
    ZTest::assert_equal(1.2.3.4/24, 1.2.3.4/24, "didn't equal when should have");
    ZTest::assert_equal(T, T, "bool didn't equal");
    local t = current_time();
    ZTest::assert_equal(t, t, "Times didn't equal");
    ZTest::assert_equal(1sec, 1sec, "Intervals didn't equal");
    ZTest::assert_equal(/asdf/, /asdf/, "Patterns didn't equal");
    ZTest::assert_equal(53/udp, 53/udp, "Ports didn't equal");
    ZTest::assert_equal(Red, Red, "Enums didn't equal");
    # TODO: When we fix the issue with table ordering (via BIF) we can also check that tables are the same when instantiated out of order
    ZTest::assert_equal(MyRecordType($c=42, $s="hi"), MyRecordType($c=42, $s="hi"), "Records didn't equal");
    ZTest::assert_equal(table([11] = "eleven", [12] = "twelve"), table([12] = "twelve", [11] = "eleven"), "Tables didn't equal");
    # TODO: When we fix the issue with set ordering (via BIF) we can also check that sets are the same when instantiated out of order
    ZTest::assert_equal(set(1, 2, 3, 4), set(1, 2, 3, 4), "Sets didn't equal");
    ZTest::assert_equal(vector(1, 1, 1, 2), vector(1, 1, 1, 2), "Vectors didn't equal");
});

ZTest::test("Assert Tests", function () {
    ZTest::assert(T, "true assertion didn't work");
});

ZTest::test("Assert Instance Of Tests", function () {
    ZTest::assert_instance_of("count", 1, "count instance of");
    ZTest::assert_instance_of("double", 1.0, "double instance of");
    ZTest::assert_instance_of("int", +1, "int instance of");
    ZTest::assert_instance_of("string", "hi", "string instance of");
    ZTest::assert_instance_of("addr", 1.2.3.4, "addr instance of");
    ZTest::assert_instance_of("subnet", 1.2.3.4/24, "subnet instance of");
    ZTest::assert_instance_of("bool", T, "bool instance of");
    ZTest::assert_instance_of("time", current_time(), "time instance of");
    ZTest::assert_instance_of("interval", 1sec, "interval instance of");
    ZTest::assert_instance_of("pattern", /asdf/, "pattern instance of");
    ZTest::assert_instance_of("port", 53/udp, "port instance of");
    ZTest::assert_instance_of("enum", Red, "enum instance of");
    ZTest::assert_instance_of("record { c:count; s:string; }", MyRecordType($c=42, $s="hi"), "record instance of");
    ZTest::assert_instance_of("table[count] of string", table([11] = "eleven"), "table instance of");
    ZTest::assert_instance_of("set[count]", set(1, 2, 3), "set instance of");
    ZTest::assert_instance_of("vector of count", vector(1, 2, 3), "vector instance of");
});

ZTest::test("Assert Matches Tests", function () {
    ZTest::assert_matches(/regex/, "regex", "Didn't match when whole string");
    ZTest::assert_matches(/regex/, "words around regex are here", "Didn't match partial string");
});

ZTest::test("Assert Greater Than/Equal To Tests", function () {
    ZTest::assert_greater_than(1.0, 2.0, "greater than double");
    ZTest::assert_greater_than_or_equal(1.0, 2.0, "greater than or equal double");
    ZTest::assert_greater_than_or_equal(1.0, 1.0, "greater than or equal double");
    
    ZTest::assert_greater_than(1, 2, "greater than count");
    ZTest::assert_greater_than_or_equal(1, 2, "greater than or equal count");
    ZTest::assert_greater_than_or_equal(1, 1, "greater than or equal count");
    
    ZTest::assert_greater_than(+1, +2, "greater than int");
    ZTest::assert_greater_than_or_equal(+1, +2, "greater than or equal int");
    ZTest::assert_greater_than_or_equal(+1, +1, "greater than or equal int");
});

ZTest::test("Assert Less Than/Equal To Tests", function () {
    ZTest::assert_less_than(3.0, 2.0, "less than double");
    ZTest::assert_less_than_or_equal(3.0, 2.0, "less than or equal double");
    ZTest::assert_less_than_or_equal(1.0, 1.0, "less than or equal double");
    
    ZTest::assert_less_than(3, 2, "less than count");
    ZTest::assert_less_than_or_equal(3, 2, "less than or equal count");
    ZTest::assert_less_than_or_equal(1, 1, "less than or equal count");
    
    ZTest::assert_less_than(+3, +2, "less than int");
    ZTest::assert_less_than_or_equal(+3, +2, "less than or equal int");
    ZTest::assert_less_than_or_equal(+1, +1, "less than or equal int");
});

ZTest::test("Assert in delta tests", function () {
    ZTest::assert_in_delta(3.0, 2.9, 0.1, "double at left edge of delta");
    ZTest::assert_in_delta(3.0, 3.1, 0.1, "double at right edge of delta");
    ZTest::assert_in_delta(3.0, 3.05, 0.1, "double in middle of right edge of delta");
    ZTest::assert_in_delta(3.0, 2.95, 0.1, "double in middle of left edge of delta");
    
    ZTest::assert_in_delta(3, 2, 1, "count at right edge of delta");
    ZTest::assert_in_delta(3, 3, 0.1, "count with double delta");
    ZTest::assert_in_delta(1, 2, 1, "count at left edge of delta");
    
    ZTest::assert_in_delta(+3, +2, +1, "int at right edge of delta");
    ZTest::assert_in_delta(+3, +3, 0.1, "int with double delta");
    ZTest::assert_in_delta(+1, +2, +1, "int at left edge of delta");
});

ZTest::run_tests();