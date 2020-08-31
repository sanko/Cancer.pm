package Cancer::Platform::Windows 1.0 {    # Actual cancer
    use strictures 2;

    #use Data::Dump;
    #
    use Moo::Role;
    use Types::Standard;
    use experimental 'signatures';

    sub size($s) {
        require Win32::Console;
        return Win32::Console->new->Size();
    }
};
1;
