#!perl

use lib '.', 'lib', '../lib';
use Log::Log4perl qw(:easy);
use Plumage::Ontology qw( load_ontology_data );
use Test::More;
use strict;

Log::Log4perl->easy_init( { level   => $WARN });

my %ontology = load_ontology_data();
use_ok( 'Plumage::Tools', 'load_core_data' );
my $core_data = load_core_data( debug => 0 );

ok( $core_data->{by_type}->{'electron microscopy'}, 'electron microscopy' );
ok( $core_data->{by_type}->{'nanodispenser'}, 'nanodispenser' );

ok( scalar keys %{ $core_data->{by_type} } >= 6,
    'have at least 6 core data types loaded' );

done_testing();
