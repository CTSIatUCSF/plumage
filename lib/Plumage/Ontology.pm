#!perl

package Plumage::Ontology;
use 5.12.0;
use Plumage::Config qw( get_config );
use CHI;
use File::ShareDir::ProjectDistDir;
use File::Spec 3.33 ();
use List::MoreUtils 0.33 qw( any apply uniq );
use Log::Log4perl 1.33 qw(:easy);
use Memoize qw( memoize );
use OWL::Simple::Parser 1.01;
use String::Approx 3.26 qw( amatch );
use Tree::Simple 1.18;
use base 'Exporter';
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

our @EXPORT_OK = ( 'load_ontology_data',    'clean_ontology_term',
                   'ontology_parent_chain', 'ontology_children',
                   'ontology_unrelated_near_matches'
);

Log::Log4perl->easy_init($ERROR);

###############################################################################

my $eagle_i_data_dir
    = File::Spec->catdir( dist_dir('Plumage'), 'eagle-i_data' );
my @owl_files = map { File::Spec->catdir( $eagle_i_data_dir, $_ ) }
    ( 'ero.r623.owl', 'obi-imports.r623.owl' );

###############################################################################

# returns a hash that looks like:
#
# { rna_foo => { definition => 'blah', names => ['RNA Foo', 'RNA Bar'], primary_name => 'RNA Foo' },
#   rna_bar => { definition => 'blah', names => ['RNA Foo', 'RNA Bar'], primary_name => 'RNA Foo' },
#   bleah   => { definition 'blah', names => ['BLeaH'] } }
#
# synonyms are repeated among hash keys

################################################################################

memoize('load_ontology_data');

sub load_ontology_data {

    my $use_cache = shift // 1;

    state $cache;
    unless ($cache) {
	my $config = get_config();
        $cache = CHI->new( driver   => 'File',
                           root_dir => "$config->{temp_dir}/ontology_cache" );
    }
    if ( $use_cache and $cache ) {
        my $return = $cache->get('ontology');
        return %{$return} if $return;
    }

    my ( %ontology, %id_to_label );

    for my $owl_file_path (@owl_files) {

        my $parser =
            OWL::Simple::Parser->new( owlfile        => $owl_file_path,
                                      synonym_tag    => 'obo:IAO_0000118',
                                      definition_tag => 'obo:IAO_0000115',
            );
        $parser->parse();

        for my $id ( keys %{ $parser->class } ) {
            my $owl = $parser->class->{$id};

            next
                if ( defined $owl->label
                     and $owl->label =~ m/^obsolete[_\s]/i );
            my $label = $owl->label || next;

            $label = clean_ontology_term($label);

            my $data = $ontology{$label} || {};
            $data->{primary_name} = $label;
            $data->{names}       ||= [];
            $data->{definitions} ||= [];
            $data->{id} = $id;

            my @names = ( $label, @{ $owl->synonyms || [] } );
            my %minimal_names;

        EachName:
            foreach my $name (@names) {
                $name = clean_ontology_term($name);
                my $minimal = _minimal_ontology_term($name);
                if ( $minimal_names{$minimal} ) {
                    next EachName;
                } elsif (
                    any {
                        $_ eq $name;
                    }
                    @{ $data->{names} }
                    ) {
                    next EachName;
                } else {
                    push @{ $data->{names} }, $name;
                    $minimal_names{$minimal} = $name;
                }
            }
            push @{ $data->{definitions} }, @{ $owl->definitions };
            @{ $data->{definitions} } = uniq @{ $data->{definitions} };
            if ( $data->{definitions} ) {
                $data->{definition} = join ' Alternatively: ',
                    @{ $data->{definitions} };
                $data->{definition}
                    =~ s/FIX THIS DEFINITION//; # error in cryostat definition
            }

            $id_to_label{ $owl->id } = $label;
            if ( $owl->{subClassOf} and @{ $owl->{subClassOf} } ) {
                $data->{parent_ids} = $owl->{subClassOf} || [];
                apply {s/^\s+|\s+$//gs} @{ $data->{parent_ids} };
            }

            foreach my $name ( @{ $data->{names} } ) {
                $ontology{$name} = $data;
            }
        }
    }

EachID:
    foreach my $id ( keys %id_to_label ) {
        my $label = $id_to_label{$id};
        my $data  = $ontology{$label};

        foreach my $parent_id ( @{ $data->{parent_ids} } ) {
            my $parent_label = $id_to_label{$parent_id};
            next unless $parent_label;

            my $parent_data = $ontology{$parent_label};
            next unless $parent_data;

            $data->{tree}        ||= Tree::Simple->new($label);
            $parent_data->{tree} ||= Tree::Simple->new($parent_label);
            $parent_data->{tree}->addChild( $data->{tree} );
        }

        delete $data->{parent_ids};
    }

    if ( $use_cache and $cache ) {
        $cache->set( 'ontology', \%ontology, '1 hour' );
    }

    return %ontology;
}

sub clean_ontology_term {
    my $text  = shift;
    my $clean = $text;
    $clean =~ s/[‒–—―-]/-/g;
    $clean =~ s/–/-/g;
    $clean =~ s/_/ /g;
    $clean =~ s/\s+/ /g;
    $clean =~ s/^\s+//g;
    $clean =~ s/[\s\r\n]+$//g;
    return $clean;
}

sub _minimal_ontology_term {
    my $text  = shift;
    my $clean = lc $text;
    $clean =~ s/[^a-z0-9]+//ig;
    return $clean;
}

memoize('ontology_unrelated_near_matches');

sub ontology_unrelated_near_matches {
    my $label    = shift;
    my %ontology = load_ontology_data();

    return if length $label <= 4;           # skip very short phrases
    return if !exists $ontology{$label};    # ensure label is valid

    my @raw_matches = amatch( $label, ['i 0%'], keys %ontology );
    my %filtered_matches;

    my @parents = ontology_parent_chain($label);
    my @children = ontology_children( $label, 1 );

EachMatch:
    foreach my $match (@raw_matches) {
        my $match_primary_name = $ontology{$match}->{primary_name};
        if ( $ontology{$label}->{primary_name} eq $match_primary_name ) {
            next EachMatch;
        }
        foreach my $relative ( @parents, @children ) {
            if (    $match_primary_name eq $relative
                 or $match eq $relative ) {
                next EachMatch;
            }
        }

        $filtered_matches{$match_primary_name}->{$match} = 1;
    }

    return sort { lc($a) cmp lc($b) } keys %filtered_matches;
}

memoize('ontology_children');

sub ontology_children {
    my $label = shift;
    my $all_descendants = shift || 0;
    return unless defined $label;

    my %ontology = load_ontology_data();
    my $tree_top = eval { $ontology{$label}->{tree} };
    if ( !$tree_top or $@ ) {
        return;
    }

    my @children;
    my $wanted_depth = $tree_top->getDepth() + 1;

    $tree_top->traverse(
        sub {
            my $tree = shift;
            if (    $all_descendants
                 or $tree->getDepth() == $wanted_depth ) {
                push @children, $tree->getNodeValue();
            }
        }
    );

    return sort { lc($a) cmp lc($b) } @children;
}

sub ontology_parent_chain {
    my $label    = shift;
    my %ontology = load_ontology_data();
    return unless ( $ontology{$label} );
    return _ontology_parent_chain_lookup( $label, \%ontology );
}

sub _ontology_parent_chain_lookup {
    my ( $label, $ontology ) = @_;
    state %cached_parent_chain;

    unless ( $cached_parent_chain{$label} ) {
        my $tree = $ontology->{$label}->{tree};
        if ( $tree and ref $tree and !$tree->isRoot ) {
            my $parent_tree  = $tree->getParent();
            my $parent_label = $parent_tree->getNodeValue();
            $cached_parent_chain{$label} = [
                     $label,
                     _ontology_parent_chain_lookup( $parent_label, $ontology )
            ];
        } else {
            $cached_parent_chain{$label} = [$label];
        }
    }

    return @{ $cached_parent_chain{$label} };
}

1;
