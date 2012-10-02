#!perl

package Plumage::Config;
use 5.12.0;
use Config::Tiny 2.14;
use Cwd qw( realpath );
use File::HomeDir 0.98;
use File::Spec;
use Params::Validate 1.00;
use Regexp::Common 2010010201 qw( URI );
use base 'Exporter';
use warnings;
use utf8;
binmode STDOUT, ':utf8';

our @EXPORT_OK = ('get_config');

sub get_config {

    # return cached configuration data, if available
    state $config;
    if ($config) {
        return $config;
    }

    # "role" is a role (e.g. main, dev) configured in the config file
    # "config_file" (optional) is path to configuration file to use
    my %options = validate( @_, { role => 0, config_file => 0 } );

    # Part 1: Load config file data

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

    # Part 2: Validate config file data

    $config = $raw_config->{_};

    my @supported_roles = sort grep { $_ ne '_' } keys %{$raw_config};
    my $num_roles_supported = scalar @supported_roles;

    if ($num_roles_supported) {
        if ( !defined $options{role} ) {
            my @example_calls = map {"\t$0 $_\n"} @supported_roles;
            die
                "No role specified. Maybe you want to run one of the following command lines:\n\n",
                @example_calls,
                "\nSee the configuration file at $path for details on what each of these roles mean.\n";
        } elsif ( !$raw_config->{ $options{role} } ) {
            die
                "Tried to load role `$options{role}`, but that's not defined at $path\n";
        } else {    # load role options as main options
            foreach my $key ( keys %{ $raw_config->{ $options{role} } } ) {
                $config->{$key} = $raw_config->{ $options{role} }->{$key};
            }
	    $config->{role} = $options{role};
        }
    } elsif ( !$num_roles_supported and exists $options{role} ) {
        die
            "No roles defined in configuration file at $path, but was sent role `$options{role}`";
    }

    my $output_path   = $config->{output_path};
    my $template_path = $config->{template_path};
    foreach my $set ( [ $output_path, 'output_path' ],
                      [ $template_path, 'template_path' ] ) {
        if ( !$set->[0] ) {
            die
                "No valid `$set->[1]` directory configured in configuration file at $path";
        } elsif ( !-d $set->[0] ) {
            die
                "Can't access the `$set->[1]` directory at `$set->[0]` (as configured in $path)";
        } elsif ( !-w $set->[0] ) {
            die
                "The `$set->[1]` directory at `$set->[0]` (as configured in $path) is not writable";
        }
    }

    if ( !exists $config->{resource_listings_file_path} ) {
        die "`resource_listings_file_path` is not configured in $path";
    } elsif ( !-r $config->{resource_listings_file_path} ) {
        die
            "Can't find a valid resource data file at $config->{resource_listings_file_path}, as configured in $path";
    }

    if ( $config->{site_name} !~ m/\w/ ) {
        die "No valid `site_name` configured in configuration file at $path";
    }
    if ( $config->{site_name} =~ m/\"/ ) {
        die
            "`site_name` in configuration file at $path can't have a quote in it";
    }

    $config->{institution_short_name} //= $config->{site_name};
    if ( $config->{institution_short_name} !~ m/\w/ ) {
        die "No valid `institution_short_name` configured in configuration file at $path";
    }

    unless (     $config->{url}
             and $config->{url} =~ m/$RE{URI}{HTTP}/ ) {
        die "No valid `url` URL configured in configuration file at $path";
    }

    if ( $config->{disable_location_filter} ) {
        if ( $config->{disable_location_filter}
             =~ m/^\s*(1|yes|on|true)\s*$/i ) {
            $config->{disable_location_filter} = 1;
        } else {
            die
                "`disable_location_filter` is set to '$config->{disable_location_filter}' -- please set it to either 1 or 0";
        }
    } else {
        $config->{disable_location_filter} = 0;
    }

    if ( defined $config->{temp_dir} ) {
        unless ( -d $config->{temp_dir} ) {
            mkdir $config->{temp_dir} || die $!;
        }
        unless ( -d $config->{temp_dir} and -w $config->{temp_dir} ) {
            warn
                "`temp_dir` configured in $path isn't a valid writable directory, will switch back to default\n";
            delete $config->{temp_dir};
        }
    }
    unless ( defined $config->{temp_dir} ) {
        $config->{temp_dir}
            = File::Spec->catdir( File::Spec->tmpdir(), 'plumage' );
    }

    return $config;
}

1;
