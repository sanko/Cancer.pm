requires 'Acme::Parataxis';
requires 'Affix';
recommends 'Term::ReadKey';
recommends 'Win32::API';
on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
    requires 'perl',                'v5.40.0';
};
