#!perl

package Plumage::Config;
use 5.12.0;
use Config::Tiny 2.14;
use Cwd qw( realpath );
use File::Spec;
use Params::Validate 1.00;
use Regexp::Common 2010010201 qw( URI );
use base 'Exporter';
use warnings;
use utf8;
binmode STDOUT, ':utf8';

our @EXPORT_OK = ('get_config');

sub get_config {

    # "role" is a role (e.g. main, dev) configured in the config file
    # "config_file" (optional) is path to configuration file to use
    my %options = validate( @_, { role => 0, config_file => 0 } );

    my @potential_config_dirs = ( '/etc/',
                                  File::HomeDir->my_home,
                                  File::Spec->curdir(),
                                  File::Spec->updir(),
                                  File::Spec->catdir( File::Spec->updir(),
                                                      File::Spec->updir()
                                  )
    );
    my @potential_config_files
        = map { realpath( File::Spec->catfile( $_, 'plumage.conf' ) ) }
        @potential_config_dirs;
    if ( $options{config_file} ) {
        @potential_config_files = ( $options{config_file} );
    }

    my ( $path, $raw_config );
    foreach my $potential_path (@potential_config_files) {
        if ( -e $potential_path ) {
            $raw_config = Config::Tiny->read($potential_path);
            unless ($raw_config) {
                die "Could not read configuration file at $potential_path: "
                    . Config::Tiny->errstr;
            }
            $path = $potential_path;
        }
    }

    unless ($raw_config) {
        die "Could not find config file, looked in: ",
            join( ', ', @potential_config_files ), "\n";
    }
    unless ( $raw_config->{_} ) {
        die "Config file at $path appeared to be empty\n";
    }

    my $config = $raw_config->{_};

    my $num_roles_supported = ( scalar( keys %{$raw_config} ) - 1 );

    if ($num_roles_supported) {
        if ( !defined $options{role} ) {
            die "No role defined";
        } elsif ( !$raw_config->{ $options{role} } ) {
            die
                "Tried to load role `$options{role}`, but that's not defined at $path\n";
        } else {
            foreach my $key ( keys %{ $raw_config->{ $options{role} } } ) {
                $config->{$key} = $raw_config->{ $options{role} }->{$key};
            }
        }
    } elsif ( !$num_roles_supported and exists $options{role} ) {
        die
            "No roles defined in configuration file at $path, but was sent role `$options{role}`";
    }

    my $output_path   = $config->{output_path};
    my $template_path = $config->{template_path};
    foreach my $set ( [ $output_path, 'output_path' ],
                      [ $template_path, 'template_path' ] ) {
        unless ( $set->[0] ) {
            die
                "No valid `$set->[1]` directory configured in configuration file at $path";
        }
        unless ( -d $set->[0] ) {
            die
                "Can't find `$set->[1]` directory at `$set->[0]` (as configured in $path)";
        }
    }

    if ( $config->{site_name} !~ m/\w/ ) {
        die "No valid `site_name` configured in configuration file at $path";
    }
    if ( $config->{site_name} =~ m/\"/ ) {
        die
            "`site_name` in configuration file at $path can't have a quote in it";
    }

    unless (     $config->{url}
             and $config->{url} =~ m/$RE{URI}{HTTP}/ ) {
        die "No valid `url` URL configured in configuration file at $path";
    }

    return $config;
}

1;
