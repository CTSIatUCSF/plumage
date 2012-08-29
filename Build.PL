use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plumage',
    license             => 'bsd',
    dist_author         => q{Anirvan Chatterjee <anirvan.chatterjee at ucsf dot edu>},
    dist_version_from   => 'lib/Plumage.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Plumage-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
