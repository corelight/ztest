# @TEST-EXEC: zeek %INPUT &> output
# @TEST-EXEC: btest-diff output

@load ztest

module TestSuite;
export {
    type color: enum {Red, White, Blue};
    type MyRecordType: record {
        c: count;
        s: string;
    };
}

ZTest::test_suite("Fail Suite 1");

ZTest::test("Assert Equal Tests", function() {
    ZTest::assert_equal(1, 2, "1 didn't equal 1");
    ZTest::assert_equal(1.0, 2.0, "didn't equal when should have");
    ZTest::assert_equal(+1, +2, "didn't equal when should have");
    ZTest::assert_equal("hi", "i", "didn't equal when should have");
    ZTest::assert_equal(1.2.3.4, 1.3.3.4, "didn't equal when should have");
    ZTest::assert_equal(1.2.3.4/24, 1.3.3.4/24, "didn't equal when should have");
    ZTest::assert_equal(T, F, "bool didn't equal");
    const t = double_to_time(0.);
    const t2 = double_to_time(1.);
    ZTest::assert_equal(t, t2, "Times didn't equal");
    ZTest::assert_equal(1sec, 2sec, "Intervals didn't equal");
    ZTest::assert_equal(/asdf/, /sdf/, "Patterns didn't equal");
    ZTest::assert_equal(53/udp, 5/udp, "Ports didn't equal");
    ZTest::assert_equal(Red, Blue, "Enums didn't equal");
    ZTest::assert_equal(MyRecordType($c=43, $s="hi"), MyRecordType($s="hi", $c=42), "Records didn't equal");
    ZTest::assert_equal(table([11] = "eleven", [12] = "twelve"), table([12] = "twelve", [11] = "eleven"), "Tables didn't equal");
    ZTest::assert_equal(set(1, 2, 3, 5), set(4, 3, 2, 1), "Sets didn't equal");
    ZTest::assert_equal(vector(1, 1, 1, 3), vector(2, 1, 1, 2), "Vectors didn't equal");
});

ZTest::test("Assert Tests", function () {
    ZTest::assert(F, "true assertion didn't work");
});

ZTest::test("Assert Instance Of Tests", function () {
    ZTest::assert_instance_of("count", 1.0, "count instance of");
    ZTest::assert_instance_of("double", 1, "double instance of");
    ZTest::assert_instance_of("int", 1, "int instance of");
    ZTest::assert_instance_of("string", 1, "string instance of");
    ZTest::assert_instance_of("addr", 1.2.3.4/24, "addr instance of");
    ZTest::assert_instance_of("subnet", 1.2.3.4, "subnet instance of");
    ZTest::assert_instance_of("bool", 1, "bool instance of");
    ZTest::assert_instance_of("time", 1, "time instance of");
    ZTest::assert_instance_of("interval", 1, "interval instance of");
    ZTest::assert_instance_of("pattern", 1, "pattern instance of");
    ZTest::assert_instance_of("port", 1, "port instance of");
    ZTest::assert_instance_of("enum", "hi", "enum instance of");
    ZTest::assert_instance_of("record { c:count; s:string; }", 1, "record instance of");
    ZTest::assert_instance_of("table[count] of string", 1, "table instance of");
    ZTest::assert_instance_of("set[count]", 1, "set instance of");
    ZTest::assert_instance_of("vector of count", 1, "vector instance of");
});

ZTest::test("Assert Matches Tests", function () {
    ZTest::assert_matches(/reex/, "regex", "Didn't match when whole string");
    ZTest::assert_matches(/regex hi/, "words around regex are here", "Didn't match partial string");
});

ZTest::test("Assert Greater Than/Equal To Tests", function () {
    ZTest::assert_greater_than(3.0, 2.0, "greater than double");
    ZTest::assert_greater_than(3.0, 3.0, "greater than double");
    ZTest::assert_greater_than_or_equal(3.0, 2.0, "greater than or equal double");
    
    ZTest::assert_greater_than(3, 2, "greater than count");
    ZTest::assert_greater_than(3, 3, "greater than count");
    ZTest::assert_greater_than_or_equal(3, 2, "greater than or equal count");
    
    ZTest::assert_greater_than(+3, +2, "greater than int");
    ZTest::assert_greater_than(+2, +2, "greater than int");
    ZTest::assert_greater_than_or_equal(+3, +2, "greater than or equal int");
});

ZTest::test("Assert Less Than/Equal To Tests", function () {
    ZTest::assert_less_than(1.0, 2.0, "less than double");
    ZTest::assert_less_than(2.0, 2.0, "less than double");
    ZTest::assert_less_than_or_equal(1.0, 2.0, "less than or equal double");
    
    ZTest::assert_less_than(1, 2, "less than count");
    ZTest::assert_less_than(1, 1, "less than count");
    ZTest::assert_less_than_or_equal(1, 2, "less than or equal count");
    
    ZTest::assert_less_than(+1, +2, "less than int");
    ZTest::assert_less_than(+2, +2, "less than int");
    ZTest::assert_less_than_or_equal(+1, +2, "less than or equal int");
});

ZTest::test("Assert in delta tests", function () {
    ZTest::assert_in_delta(3.1, 2.9, 0.1, "double at left edge of delta");
    ZTest::assert_in_delta(2.9, 3.1, 0.1, "double at right edge of delta");
    
    ZTest::assert_in_delta(3, 5, 1, "count at right edge of delta");
    ZTest::assert_in_delta(3, 1, 1, "count at left edge of delta");
    
    ZTest::assert_in_delta(+3, +5, +1, "int at right edge of delta");
    ZTest::assert_in_delta(+3, +1, +1, "int at left edge of delta");
});

ZTest::run_tests();
