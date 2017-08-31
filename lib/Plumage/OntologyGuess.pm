#!perl

package Plumage::OntologyGuess;
use 5.12.0;
use lib '.', '..', 'lib', '../lib';
use Plumage::Ontology qw( load_ontology_data );
use File::Temp;
use KSx::Simple;
use List::MoreUtils qw( none uniq );
use base 'Exporter';
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

our @EXPORT_OK = qw( guess_ontology_mappings );

sub guess_ontology_mappings {

    my $search_term        = shift;
    my $num_matches        = shift // 10;
    my $ontology_root_term = shift // undef;

    state( %ontology, $global_index, %root_indexes );
    unless (%ontology) {
        %ontology = load_ontology_data();
    }

    my $index;

    # create index if needed
    if (    ( $ontology_root_term and !$root_indexes{$ontology_root_term} )
         or ( !$ontology_root_term and !$global_index ) ) {

        my ( %primary_names, %content_to_index );

        if ($ontology_root_term) {
            $primary_names{$ontology_root_term} = 1;
            my $tree_top = $ontology{$ontology_root_term}->{tree};
            $tree_top->traverse(
                sub {
                    $primary_names{ $_[0]->getNodeValue() } = 1;
                }
            );
        } else {
            foreach my $term ( keys %ontology ) {
                my $primary_name = $ontology{$term}->{primary_name};
                $primary_names{$primary_name} = 1;
            }
        }

        foreach my $primary_name ( sort keys %primary_names ) {
            foreach my $name ( @{ $ontology{$primary_name}->{names} } ) {
                $content_to_index{$name} = $primary_name;
            }
        }

        $index = _make_search_index( \%content_to_index );

        if ($ontology_root_term) {
            $root_indexes{$ontology_root_term} = $index;
        } else {
            $global_index = $index;
        }
    } elsif ($ontology_root_term) {
        $index = $root_indexes{$ontology_root_term};
    } else {
        $index = $global_index;
    }

    my $hits
        = $index->search( query => $search_term, num_wanted => $num_matches );
    my @matches;
    if ($hits) {
        while ( my $hit = $index->next ) {
            my $ontology_term = $hit->{master};
            if ( $hit->{title} eq $hit->{master} ) {
                push @matches, $hit->{title};
            } else {
                push @matches, "$hit->{title} [$hit->{master}]";
            }
        }
    }

    return @matches;
}

# takes a hash of { "title1" => "master name 1", "title 2" => "master name 2" }
# returns a KSx::Simple index of that content,
#   with hits like { title => "title 1", master => "master name 1" }
sub _make_search_index {
    my $content_to_index = shift;

    state @index_dirs;

    my $dir = File::Temp->newdir();
    push @index_dirs, $dir;    # ensure it'll be deleted at close

    my $index = KSx::Simple->new( path => $dir->dirname, language => 'en' );
    foreach my $title ( keys %{$content_to_index} ) {
        $index->add_doc(
                   { title => $title, master => $content_to_index->{$title} } );
    }
    return $index;
}

1;
