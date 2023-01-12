requires 'perl', '5.022000';
requires 'Fcntl';
requires 'POSIX';
requires 'IO::Select';
requires 'Carp';
requires 'Moo';
requires 'Types::Standard';
requires 'Role::Tiny';
on 'configure' => sub {
    requires 'Module::Build::Tiny';
};
on 'test' => sub {
    requires 'Test2::V0';
    requires 'Test2::Tools::Exception';
};
