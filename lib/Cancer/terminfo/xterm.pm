package Cancer::terminfo::xterm {
    use strict;
    use warnings;

    #use Data::Dump;
    use Fcntl qw[O_RDWR O_NDELAY O_NOCTTY];
    use POSIX qw[:termios_h];
    use IPC::Open2;
    #
    use Moo::Role;
    use Types::Standard qw[Bool Enum HashRef FileHandle InstanceOf Int Num Str];
    use experimental 'signatures';
    use Role::Tiny qw[];
    with 'Cancer::terminfo';
    #
}
1;
