# This script tests ZTest features
$had_failure = false
# Change if zeek isn't in your PATH
$zeek_path = "zeek"

def failure_puts(message)
    had_failure = true
    puts message
end

def run_and_check_output(test_name, condition, message)
    output = `#{$zeek_path} ./test_cases/#{test_name}`
    successful = true
    if condition.is_a? Regexp
        if output !~ condition
            successful = false
        end
    elsif condition.is_a? Integer
        if $?.exitstatus != condition
            successful = false
        end
    end
    if !successful
        failure_puts message
        puts output
        $had_failure = true
    end
end


# 01 Test suppressing success output
run_and_check_output("01_success_not_suppressed.zeek", /Total Assertions/, "Didn't see success output when not suppressing it")
run_and_check_output("01_success_suppressed_no_errors.zeek", /^$/, "Saw success output when not expecting to")
run_and_check_output("01_success_suppressed_with_failures.zeek", /1 didn't equal 2/, "Didn't see failure output when suppressing success output")

# 02 Test suppressing all output
run_and_check_output("02_all_output_suppressed.zeek", /^$/, "Saw some output when all output was supposed to be suppressed")

# 03 Test hooking the Zeek exit
run_and_check_output("03_hook_exit_success.zeek", 0, "Didn't observe an exit code of 0 when there were no failures")
run_and_check_output("03_hook_exit_failure.zeek", 1, "Didn't observe an exit code of 1 when there was a failure and we were hooking the exit")

# 04 Test assert cases
run_and_check_output("04_assert_pass_cases.zeek", /0 failed assertions/, "Didn't see all assert_equal cases pass")
run_and_check_output("04_assert_fail_cases.zeek", /59 failed assertions/, "Didn't see all assert_equal cases fail")

# 05 Test retrieving results
run_and_check_output("05_retrieve_results.zeek", /Made it to the end without any invalid table key errors!/, "Didn't Properly retrieve all results")

# 06 Test Manual test_exit
run_and_check_output("06_manual_exit_with_success.zeek", 0, "Didn't observe an exit code of 0 when there were no failures on a manual exit")
run_and_check_output("06_failure_with_no_exit_hook.zeek", 0, "Didn't observe an exit code of 0 when there were failures but no manual exit or hook")
run_and_check_output("06_manual_exit_with_failure.zeek", 1, "Didn't observe an exit code of 1 when there were failures on a manual exit")

# 07 Tests run if run wasn't called
run_and_check_output("07_no_run_called.zeek", /Total Assertions/, "Didn't see success output when not calling ZTest::run_tests()")

# 08 Tests run when switching test suites without calling run
run_and_check_output("08_switch_suites_without_running.zeek", /Suite 1.*Suite 2/m, "Didn't see success output when not calling ZTest::run_tests() in between test suites")

if $had_failure
    puts "Had at least one test failure! Exiting with status of 1"
    exit(1)
else
    puts "All tests completed successfully"
end