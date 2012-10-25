#!perl

use lib '.', 'lib', '../lib';
use JSON qw( decode_json );
use Test::More;
use strict;
binmode STDOUT, ':utf8';

plan tests => 2;

use_ok( 'Plumage::EagleIData', 'extract_eagle_i_data' );

eval {
    my $json_raw  = extract_eagle_i_data('http://alaska.eagle-i.net/');
    my $json_data = decode_json($json_raw);
    ok( ( $json_data and scalar keys %{$json_data} ), "Got back valid JSON" );
};

done_testing();
