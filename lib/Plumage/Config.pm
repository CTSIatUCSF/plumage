#!perl

package Plumage::Config;
use 5.12.0;
use Config::Tiny 2.14;
use Cwd qw( realpath );
use File::Spec;
use Regexp::Common 2010010201 qw( URI );
use base 'Exporter';
use warnings;
use utf8;
binmode STDOUT, ':utf8';

our @EXPORT_OK = ('get_config');

sub get_config {

    my ( $role, $config_file ) = @_;

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
    if ($config_file) {
        @potential_config_files = ($config_file);
    }

    my ( $path, $raw_config );
    foreach $path (@potential_config_files) {
        if ( -e $path ) {
            $raw_config = Config::Tiny->read($path)
                || die "Could not read configuration file at $path: "
                . Config::Tiny->errstr;
            last;
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

    if ($role) {
        if ( $raw_config->{$role} ) {
            foreach my $key ( keys %{ $raw_config->{$role} } ) {
                $config->{$key} = $raw_config->{$role}->{$key};
            }
        } else {
            die "Tried to load role `$role`, but that's not defined at $path";
        }
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
