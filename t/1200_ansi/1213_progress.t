use Test2::V1 -ipP;
use blib;
use Cancer::Ansi qw[set_progress_bar set_error_progress_bar set_warning_progress_bar];
#
subtest set_progress_bar => sub {
    is set_progress_bar(50),  "\e]9;4;1;50\a",  'SetProgress(50)';
    is set_progress_bar(-2),  "\e]9;4;1;0\a",   'SetProgress(-2)';
    is set_progress_bar(200), "\e]9;4;1;100\a", 'SetProgress(200)';
};
subtest set_error_progress_bar => sub {
    is set_error_progress_bar(50),  "\e]9;4;2;50\a",  'SetErrorProgress(50)';
    is set_error_progress_bar(-2),  "\e]9;4;2;0\a",   'SetErrorProgress(-2)';
    is set_error_progress_bar(200), "\e]9;4;2;100\a", 'SetErrorProgress(200)';
};
subtest set_warning_progress_bar => sub {
    is set_warning_progress_bar(50),  "\e]9;4;4;50\a",  'SetWarningProgress(50)';
    is set_warning_progress_bar(-2),  "\e]9;4;4;0\a",   'SetWarningProgress(-2)';
    is set_warning_progress_bar(200), "\e]9;4;4;100\a", 'SetWarningProgress(200)';
};
#
done_testing;
