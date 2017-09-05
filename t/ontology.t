#!perl

use lib '.', 'lib', '../lib';
use Test::More;
use strict;
binmode STDOUT, ':utf8';

use_ok( 'Plumage::Ontology',     'load_ontology_data',
        'ontology_parent_chain', 'ontology_children' );

my %ontology = load_ontology_data(0);

foreach my $term ( sort keys %ontology ) {
    unlike( $term, qr{^\s|\s+$}, qq{No extra whitespace in "$term"} );
    like( $term,
          qr{^[[:alpha:][:digit:][:punct:] ]+$},
          qq{Only reasonable characters in "$term"} );
}

ok( exists $ontology{freezer}, "freezer is in ontology" );
like( $ontology{freezer}->{definitions}->[0],
      qr/thermally insulated/,
      'freezer definition makes sense' );
is_deeply( $ontology{freezer}->{names},
           ['freezer'], 'freezer has no synonyms' );

is_deeply( [ ontology_parent_chain('imaging technique') ],
           [  'imaging technique', 'technique',
              'planned process',   'process',
              'occurrent',         'entity'
           ],
           'ontology_parent_chain: imaging technique'
);

is_deeply( [ ontology_parent_chain('instrument') ],
           [  'instrument',             'material entity',
              'independent continuant', 'continuant',
              'entity'
           ],
           'ontology_parent_chain: instrument'
);

done_testing();
