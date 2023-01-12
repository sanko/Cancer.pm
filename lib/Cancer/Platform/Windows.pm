package Cancer::Platform::Windows 0.01 {    # Actual cancer
    use strict;
    use warnings;

    #use Data::Dump;
    #
    use Moo::Role;
    use Types::Standard;
    use experimental 'signatures';

    sub size ($s) {
        require Win32::Console;
        return Win32::Console->new->Size();
    }
};
1;
