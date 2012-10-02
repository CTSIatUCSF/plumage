#!perl

use lib '.', 'lib', '../lib';
use Plumage::Ontology qw( load_ontology_data );
use Test::More;
use strict;

my %ontology = load_ontology_data();
use_ok( 'Plumage', 'load_core_data' );
my $core_data = load_core_data( debug => 0 );

ok( $core_data->{by_type}->{'microtome'}, 'microtome' );
ok( $core_data->{by_type}->{'FACS'}, 'FACS' );

ok( scalar keys %{ $core_data->{by_type} } >= 150,
    'have at least 150 core data types loaded' );

done_testing();
