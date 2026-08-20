requires 'Acme::Parataxis';
requires 'Affix';
recommends 'Term::ReadKey';
on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
    requires 'perl',                'v5.40.0';
};
