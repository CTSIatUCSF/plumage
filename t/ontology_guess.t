#!perl

use lib '/var/www/html/cores/tools/code/lib';
use Test::More;
use strict;
binmode STDOUT, ':utf8';

use_ok( 'Plumage::OntologyGuess', 'guess_ontology_mappings' );

my @guesses;

@guesses = guess_ontology_mappings('dexa');
is( $guesses[0], 'DEXA [dual energy x-ray absorptiometry]', 'DEXA' );

@guesses = guess_ontology_mappings('UCSF Supercritical processor core');
like( $guesses[0], qr/^Supercritical processor/i, 'Supercritical processor' );

@guesses = guess_ontology_mappings('freezer', 10, 'technique');
is_deeply(\@guesses, [], 'freezer is not a technique');

@guesses = guess_ontology_mappings('freezer', 10, 'technique');
is_deeply(\@guesses, [], 'freezer is not a technique (2nd time should be fast/correct)');

done_testing();
