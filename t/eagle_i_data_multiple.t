#!perl

use lib '.', 'lib', '../lib';
use JSON qw( decode_json );
use Log::Log4perl qw(:easy :no_extra_logdie_message);
use Test::More;
use strict;
binmode STDOUT, ':utf8';

plan tests => 4;

use_ok( 'Plumage::EagleIData', 'extract_eagle_i_data' );

eval {
    my $json_raw = extract_eagle_i_data( 'http://alaska.eagle-i.net/',
                                         'http://jsu.eagle-i.net/' );
    my $json_data = decode_json($json_raw);
    ok( ( $json_data and scalar keys %{$json_data} ), "Got back valid JSON" );
    like( $json_raw, qr/\balaska\b/i,        'Got back Alaska data' );
    like( $json_raw, qr/\b(jsu|jackson)\b/i, 'Got back JSU data' );
};

done_testing();
