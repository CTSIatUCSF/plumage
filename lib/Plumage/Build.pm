#!/usr/bin/perl

package Plumage::Build;
use 5.12.0;
use lib '.', 'lib', '../lib';
use File::Spec;
use File::Copy::Recursive 0.09 qw( rcopy );
use File::Remove 1.50 qw( remove );
use Filesys::DiskUsage qw( du );
use File::Spec;
use File::Path qw( remove_tree );
use JSON 2.0 qw( encode_json );
use Log::Log4perl qw(:easy);
use Plumage::Config qw( get_config );
use Plumage::Tools
    qw( load_core_data get_freebase_definition name_to_filename );
use Plumage::Ontology 'load_ontology_data', 'ontology_parent_chain',
    'ontology_children';
use Plumage::Swiftype;
use Search::Sitemap 2.13;
use Template 2.22;
use Template::Stash::AutoEscaping 0.0301;
use strict;
use warnings;
binmode STDERR, ':utf8';
binmode STDOUT, ':utf8';
use open ':encoding(utf8)';

our ( $template, $config, $output_path, $template_path,
      $dynamic_template_path, $custom_template_path,
      $dynamic_custom_template_path, $sitemap );

sub build {
    $config        = get_config();
    $output_path   = $config->{output_path};
    $template_path = $config->{template_path};
    $dynamic_template_path
        = File::Spec->catdir( $config->{template_path}, 'dynamic' );
    $custom_template_path = $config->{custom_template_path};
    $dynamic_custom_template_path
        = File::Spec->catdir( $config->{custom_template_path}, 'dynamic' );

    ###########################################################################

    my %ontology          = load_ontology_data();
    my $core_data         = load_core_data( ontology => \%ontology );
    my $core_data_by_type = $core_data->{by_type};

    ###########################################################################

    INFO("Building website");

    # blow away output directory
    {

        unless (
            $config->{disable_safety_check_before_deleting_output_directory} )
        {
            my $total_size_of_output_dir_in_kb = du($output_path) / 1024;
            if ( $total_size_of_output_dir_in_kb >= 10_240 ) {
                LOGDIE
                    "Output directory `$output_path` is over 10 MB in size -- not going to delete it, just to be safe\n\nTo disable this check, add `disable_safety_check_before_deleting_output_directory = 1` to the config file";
            }
        }

        my $to_remove_path_with_wildcard
            = File::Spec->catfile( $output_path, '*' );
        remove( \1, $to_remove_path_with_wildcard );
    }

    # copy over static files
    {
        my $static_dir = File::Spec->catdir( $template_path, 'static' );
        unless ( -e $static_dir ) {
            LOGDIE "Can't find directory of static content `$static_dir`";
        }
        rcopy( $static_dir, $output_path );

        if ($custom_template_path) {
            my $custom_static_dir
                = File::Spec->catdir( $custom_template_path, 'static' );
            if ( -e $custom_static_dir ) {
                rcopy( $custom_static_dir, $output_path );
            }
        }

    }

    # We should be using only $dynamic_template_path and
    # $custom_template_path, but before Feb 2013, Plumage used to put
    # dynamic templates inside the main template directory. Adding
    # $template_path back in ensures that the system should be
    # backwards compatible.
    my @valid_template_paths = grep {defined} (
                         $dynamic_custom_template_path, $custom_template_path,
                         $dynamic_template_path,        $template_path );

    $template = Template->new( { EVAL_PERL  => 1,
                                 PRE_CHOMP  => 0,
                                 POST_CHOMP => 1,
                                 STASH => Template::Stash::AutoEscaping->new,
                                 ENCODING     => 'utf8',
                                 INCLUDE_PATH => \@valid_template_paths,
                               }
    );

    $sitemap = Search::Sitemap->new();

    my %terms_done;

    foreach my $type ( sort { lc($a) cmp lc($b) } keys %{$core_data_by_type} )
    {
        my $ontology_data = $ontology{$type} || next;

        my $definition = $ontology_data->{definition};
        unless ($definition) {
            foreach my $name ( @{ $core_data_by_type->{$type}->{names} } ) {
                my $definition_lookup = get_freebase_definition($name)
                    or next;
                $definition = $definition_lookup;
                last;
            }
        }

        my @names = @{ $core_data_by_type->{$type}->{names} };

        foreach my $name (@names) {
            if ( $terms_done{$name} ) {
                next;
            }

            my @synonyms = grep { $_ ne $name } @names;
            @synonyms
                = map { { name => $_, filename => name_to_filename($_) } }
                @synonyms;

            my @parents = ontology_parent_chain($type);
            shift @parents;    # remove self
            if ( @parents >= 3 ) {    # use no more than 3 levels of parents
                $#parents = 2;
            }
            @parents = reverse @parents;    # biggest first
            @parents = grep { $core_data_by_type->{$_} } @parents;
            @parents = map {
                {  name     => ucfirst $ontology{$_}->{names}->[0],
                   filename => name_to_filename($_)
                }
            } @parents;

            my @all_children = ontology_children($type);
            my @children;
            foreach my $child (@all_children) {
                if ( $core_data_by_type->{$child} ) {
                    push @children, $child;
                } else {
                    my @grandchildren = ontology_children($child);
                    my @valid_grandchildren
                        = grep { $core_data_by_type->{$_} } @grandchildren;
                    push @children, @valid_grandchildren;
                }
            }
            @children = sort { lc($a) cmp lc($b) } @children;

            @children = map {
                {  name     => ucfirst $ontology{$_}->{names}->[0],
                   filename => name_to_filename($_)
                }
            } @children;

            my $vars = { name       => $name,
                         synonyms   => \@synonyms,
                         parents    => \@parents,
                         children   => \@children,
                         definition => $definition,
                         data       => $core_data_by_type->{$type},
            };

            my $filename = name_to_filename($name);
            write_file( 'resource.html.tt', "/$filename", $vars );
            $terms_done{$name} = 1;
        }
    }

    write_file( 'about.html.tt',  '/about/' );
    write_file( 'search.html.tt', '/search/' );

    {
        my $options = { stats => $core_data->{stats} };
        foreach my $type ( sort keys %{$core_data_by_type} ) {
            foreach my $name ( @{ $core_data_by_type->{$type}->{names} } ) {
                $options->{types}->{$name} = {
                                 filename => name_to_filename($name),
                                 count => $core_data_by_type->{$type}->{count}
                };
            }
        }
        write_file( 'index.html.tt', '/', $options );
    }

    {
        my %term_to_url;
        foreach my $ontology_term ( sort keys %terms_done ) {
            my $filename = name_to_filename($ontology_term);
            my $url      = "$config->{url}$filename";
            $term_to_url{$ontology_term} = $url;
        }
        my $term_to_url_json = encode_json( \%term_to_url );
        write_file( 'generated.js.tt', '/assets/js/generated.js',
                    { typeahead_data_json => $term_to_url_json } );
    }

    {
        my $sitemap_location = "assets/sitemap.xml";
        my $sitemap_path     = "$output_path/$sitemap_location";
        my $sitemap_url      = "$config->{url}/$sitemap_location";

        my ( $vol, $dir, $file ) = File::Spec->splitpath($sitemap_path);
        mkdir($dir) unless -d $dir;
        unlink $sitemap_path;

        $sitemap->pretty(1);
        $sitemap->write($sitemap_path);

        write_file( 'robots.txt.tt', '/robots.txt',
                    { sitemap_url => $sitemap_url } );
    }

    {
        if ( $config->{build_deploy_command} ) {
            INFO
                qq{About to run deploy command "$config->{build_deploy_command}"\n};
            system $config->{build_deploy_command};
        }
    }

    {
        if ( $config->{swiftype_key} ) {
            Plumage::Swiftype::swiftype_reindex();
        }
    }

    INFO "Done building website for $config->{url}";

    return 1;
}

###############################################################################

sub write_file {
    my ( $template_name, $url_path, $options ) = @_;

    # ensure URL path is reasonable
    unless ( defined $url_path and $url_path =~ m{^/} ) {
        LOGCROAK qq{Invalid URL path "$url_path"};
    }

    # add config options to options hash
    $options ||= {};
    $options->{config} = $config;

    # create full path
    my $full_path = $output_path . $url_path;
    if ( $url_path =~ m{/$} ) {
        $full_path .= 'index.html';
    }

    # delete old file, ensure directory exists
    unlink $full_path;
    my ( $vol, $dir, $file ) = File::Spec->splitpath($full_path);
    mkdir($dir) unless -d $dir;

    # write...
    open my $out, '>', $full_path;
    $template->process( $template_name, $options, $out,
                        { binmode => ':encoding(UTF-8)' } )
        || LOGCROAK( "Template processing error: " . $template->error() );

    # add to sitemap
    add_url_to_sitemap($url_path);

    return;
}

sub add_url_to_sitemap {
    my $path = shift;
    my $url  = "$config->{url}$path";
    $url =~ s{(?<!:)//}{/}g;
    $sitemap->add( Search::Sitemap::URL->new( loc        => $url,
                                              lastmod    => time(),
                                              changefreq => 'weekly',
                                              priority   => 1.0,
                   )
    );
}

1;
