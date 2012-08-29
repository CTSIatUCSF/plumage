#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plumage' ) || print "Bail out!\n";
}

diag( "Testing Plumage $Plumage::VERSION, Perl $], $^X" );
