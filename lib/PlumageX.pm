#!/usr/bin/perl

package Plumage;
use 5.12.0;
use lib '/var/www/html/cores/tools/code/lib';
use JSON qw( decode_json );
use LWP::Simple qw( get );
use LWP::Simple::WithCache;
use Memoize qw( memoize );
use Text::Elide qw( elide );
use Plumage::Ontology qw( load_ontology_data clean_ontology_term );
use Plumage::OntologyGuess qw( guess_ontology_mappings );
use URI::Escape qw( uri_escape );
use base 'Exporter';
use strict;
use warnings;
binmode STDOUT, ':utf8';

our @EXPORT_OK
    = qw( load_core_data get_freebase_definition name_to_filename );

###############################################################################

my $dump_data_mode = 0;

memoize('load_core_data');

sub load_core_data {
    my %options = @_;
    my $debug = $options{debug} // 1;

    state $ontology ||= { load_ontology_data() };

# my master data hash, looks like:
# { by_type => { freezer => cores => { 'CoreName' => { resources => ['Mr. Freeze', 'Chiller'] } } }

    my %cores;
    my %resources_by_type;
    my %stats = ( num_types => 0, num_resources => 0, num_cores => 0 );

    {
        my $core_data_file_path = '/var/www/html/cores/tools/CoresData.json';
        open( my $fh, '<', $core_data_file_path )
            || die "Couldn't open $core_data_file_path: $!";
        my $cores_data = decode_json( join '', <$fh> );

        close($fh);
        %cores = %{$cores_data};

        state %valid_ontology_terms_lc;
        unless (%valid_ontology_terms_lc) {
            foreach my $term ( keys %{$ontology} ) {
                $valid_ontology_terms_lc{ lc($term) } = $term;
            }
        }

        foreach my $core_name ( keys %cores ) {
            my $core = $cores{$core_name};
            unless ( $core->{resources} and %{ $core->{resources} } ) {
                $debug
                    and warn
                    qq{Skipping core "$core_name" which has no resouces};
                delete $cores{$core_name};
                next;
            }
            $stats{num_cores}++;

            foreach
                my $field (qw( core url organization contact phone email )) {
                $core->{$field} //= '';
            }
            $core->{location} //= '[Unknown]';
            $core->{location} =~ s/ Campus(?=,|$)//g;
            $core->{location} =~ s/\s*,\s*/, /g;
            $core->{locations} = [ split( /, ?/, $core->{location} ) ];

        EachResource:
            foreach my $raw_type ( keys %{ $core->{resources} } ) {

                my $canonical_type = $valid_ontology_terms_lc{ lc $raw_type }
                    || $raw_type;
                unless ( $ontology->{$canonical_type} ) {
                    warn qq{Could not match type "$raw_type" to the ontology};
                    next EachResource;
                }

                $core->{supported_types}->{$canonical_type} = 1;
                $resources_by_type{$canonical_type}->{cores}->{$core_name}
                    ->{info} = $core;

                foreach my $label ( @{ $core->{resources}->{$raw_type} } ) {
                    push @{ $resources_by_type{$canonical_type}->{cores}
                            ->{$core_name}->{resources} },
                        $label;
                    $resources_by_type{$canonical_type}->{count}++;
                    $stats{num_resources}++;
                }
            }

        }
    }

    $stats{num_types} = scalar keys %resources_by_type;

    $debug
        and warn
        "Used $stats{num_resources} items for $stats{num_types} types of core items\n";

    # add sorted cores to each type
    foreach my $canonical_type ( sort keys %resources_by_type ) {
        @{ $resources_by_type{$canonical_type}->{cores_sorted} } = sort {
            $a->{info}->{location} cmp $b->{info}->{location}
                || lc( $a->{info}->{core} ) cmp lc( $b->{info}->{core} )
        } values %{ $resources_by_type{$canonical_type}->{cores} };
    }

    # add sorted locations to each type
    foreach my $canonical_type ( sort keys %resources_by_type ) {
        my %locations;
        foreach my $core (
                  @{ $resources_by_type{$canonical_type}->{cores_sorted} } ) {
            foreach my $location ( @{ $core->{info}->{locations} } ) {
                $locations{$location} = 1;
            }
        }
        $resources_by_type{$canonical_type}->{locations_sorted}
            = [ sort keys %locations ];
    }

    # copy canonical type info to all other alternate names
    foreach my $canonical_type ( sort keys %resources_by_type ) {
        my @names = @{ $ontology->{$canonical_type}->{names} };
        $resources_by_type{$canonical_type}->{names}
            = [ map {ucfirst} @names ];
        foreach my $name (@names) {
            if ( $name ne $canonical_type ) {
                $resources_by_type{$name}
                    = $resources_by_type{$canonical_type};
            }
        }
    }

    my %cores_by_location;
    foreach my $core_name ( keys %cores ) {
        my @core_locations = @{ $cores{$core_name}->{locations} };
        foreach my $core_location (@core_locations) {
            push @{ $cores_by_location{$core_location} }, $cores{$core_name};
        }
    }

    return { by_type     => \%resources_by_type,
             by_core     => \%cores,
             by_location => \%cores_by_location,
             stats       => \%stats
    };
}

###############################################################################

memoize('name_to_filename');

sub name_to_filename {
    my $name     = shift;
    my $filename = lc "$name.html";
    $filename =~ s/[\s_\/-]+/-/g;
    $filename =~ s/[^A-Za-z0-9\.-]+//g;
    $filename =~ s/--+/-/;
    return $filename;
}

###############################################################################

sub get_freebase_definition {
    my $query = shift;
    my $max_length = shift || 300;

    my $match_json
        = get( 'https://www.googleapis.com/freebase/v1/search?query='
               . uri_escape($query) )
        or return;
    my $option = eval { decode_json($match_json)->{result}->[0] };
    return
        unless (     $option
                 and $option->{score} >= 500
                 and $option->{mid} );
    my $def_json
        = get("https://www.googleapis.com/freebase/v1/text$option->{mid}")
        or return;
    my $def_option = eval { decode_json($def_json)->{result} }
        or return;

    my $freebase_attribution = ' (definition via Freebase)';

    if ($max_length) {
        return elide( $def_option, $max_length ) . $freebase_attribution;
    } else {
        return $def_option . $freebase_attribution;
    }
}

1;