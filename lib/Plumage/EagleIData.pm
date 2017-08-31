#!perl

package Plumage::EagleIData;
use Encode qw( encode_utf8 );
use JSON 2.0 qw( encode_json );
use HTTP::Request::Common;
use Log::Log4perl qw(:easy);
use LWP::UserAgent::Determined;
use LWP::Protocol::https;
use LWP::Simple qw( head );
use URI;
use URI::Escape qw( uri_escape );
use XML::Simple qw(:strict);
use base 'Exporter';
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

our @EXPORT_OK = qw( extract_eagle_i_data );

our $ua;

sub extract_eagle_i_data {

    my @base_uris_text = @_;

    unless (@base_uris_text) {
        eval q{
	    use Plumage::Config qw( get_config );
	    my $config = get_config();
	    @base_uris_text = @{$config->{eagle_i_base_urls}};
	};
    }

    $ua ||= LWP::UserAgent::Determined->new;
    push @{ $ua->requests_redirectable }, 'POST';
    $ua->timing('5,5,5,5,5,5');
    $ua->ssl_opts( verify_hostname => 0 );

    my %core_data;

    for my $base_uri_num ( 0 .. $#base_uris_text ) {

        my $base_uri_num_printable   = $base_uri_num + 1;
        my $base_uri_count_printable = scalar @base_uris_text;
        my $base_uri_debug_message   = $base_uris_text[$base_uri_num]
            . " ($base_uri_num_printable of $base_uri_count_printable)";

        my $base_uri_text = $base_uris_text[$base_uri_num];
        my $base_uri      = URI->new($base_uri_text)
            || LOGCROAK
            qq{Invalid base URI "$base_uri_text", expected something more like "http://example.eagle-i.net/" or "https://eaglei.example.com/"};
        $base_uri = $base_uri->canonical;

        my $cores_list_url = $base_uri->clone;
        $cores_list_url->path('/sweet/cores/');
        $cores_list_url->query_form( format => 'application/xml' );

        my $sparql_url = $base_uri->clone;
        if ( head("${base_uri}sparqler/sparql") ) {
            $sparql_url->path('/sparqler/sparql');
        } elsif ( head("${base_uri}repository/sparql") ) {
            $sparql_url->path('/repository/sparql');
        } else {
            my $response = $ua->head("${base_uri}repository/sparql");
            if ( $response->code == 400 ) {
                $sparql_url->path('/repository/sparql');
            }
        }

        if ( $sparql_url eq $base_uri ) {
            LOGDIE("Could not identify SPARQL endpoint for $base_uri");
        }

        my $provider_url = $base_uri->clone;
        $provider_url->path('/sweet/provider');

        my %core_to_rdf_url;

        INFO("Downloading data from $base_uri_debug_message");

        {
            DEBUG('  Begin SWEET query');
            my $request = HTTP::Request->new( GET => $cores_list_url );
            my $response = $ua->request($request);
            unless ( $response->is_success ) {
                LOGDIE "COULD NOT DOWNLOAD MASTER FILE AT $cores_list_url: ",
                    $response->status_line;
            }

            my $data = XMLin( $response->content,
                              ForceArray => ['resourceProvider'],
                              KeyAttr    => ''
            );

            if ( $data and ref $data ) {
                foreach my $core ( @{ $data->{resourceProvider} } ) {
                    $core_to_rdf_url{ $core->{name} } = $core->{url};
                }
            }
            unless (%core_to_rdf_url) {
                LOGDIE
                    "COULD NOT FIND ANY CORES IN MASTER FILE at $cores_list_url";
            }
            DEBUG('    End SWEET query');
        }

        my %core_to_website;

        unless (%core_to_website) {
            DEBUG('  Begin 1.1 of 3 SPARQL queries');
            %core_to_website = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
select ?core ?website where {
?core a ero:ERO_0000002 .
?core ero:ERO_0000480 ?website .
}
', $sparql_url );
            DEBUG('    End 1.1 of 3 SPARQL queries');
        }

        unless (%core_to_website) {
            DEBUG('  Begin 1.2 of 3 SPARQL queries');
            %core_to_website = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX ero: <http://purl.obolibrary.org/obo/>
select ?core ?website where {
?core a foaf:Organization .
?core ero:ERO_0000480 ?website .
}', $sparql_url );
            DEBUG('    End 1.2 of 3 SPARQL queries');
        }

        my %core_to_location;

        unless (%core_to_location) {
            DEBUG('  Begin 2.1 of 3 SPARQL queries');
            my %core_to_location = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
select ?core ?address where {
?core a ero:ERO_0000002 .
?core ero:ERO_0000055 ?address .
}
', $sparql_url );
            DEBUG('    End 2.1 of 3 SPARQL queries');
        }

        unless (%core_to_location) {
            DEBUG('  Begin 2.2 of 3 SPARQL queries');
            %core_to_location = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
PREFIX vivo: <http://vivoweb.org/ontology/core#>
select ?core ?address where {
?core a vivo:CoreLaboratory .
?core ero:ERO_0000055 ?address .
}
', $sparql_url );
            DEBUG('    End 2.2 of 3 SPARQL queries');
        }

        unless (%core_to_location) {
            DEBUG('  Begin 2.3 of 3 SPARQL queries');
            %core_to_location = _get_sparql_data( '
PREFIX ero: <http://purl.obolibrary.org/obo/>
PREFIX vivo: <http://vivoweb.org/ontology/core#>
select ?core ?address where {
?core a vivo:CoreLaboratory .
?core ero:ERO_0000040 ?address .
}
', $sparql_url );
            DEBUG('    End 2.3 of 3 SPARQL queries');
        }

        my %resource_to_technique;

        unless (%resource_to_technique) {
            DEBUG('  Begin 3.1 of 3 SPARQL queries');
            my %resource_to_technique = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
select ?resource ?technique_label where {
?core a ero:ERO_0000002 .
?resource ?any_relationship ?core .
?resource ero:ERO_0000543 ?technique_uri .
?technique_uri rdfs:label ?technique_label
}
', $sparql_url );
            DEBUG('    End 3.1 of 3 SPARQL queries');
        }

        unless (%resource_to_technique) {
            DEBUG('  Begin 3.2 of 3 SPARQL queries');
            %resource_to_technique = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
PREFIX vivo: <http://vivoweb.org/ontology/core#>
select ?resource ?technique_label where {
?core a vivo:CoreLaboratory .
?resource ?any_relationship ?core .
?resource ero:ERO_0000543 ?technique_uri .
?technique_uri rdfs:label ?technique_label
}
', $sparql_url );
            DEBUG('    End 3.2 of 3 SPARQL queries');
        }

        unless (%resource_to_technique) {
            DEBUG('  Begin 3.3 of 3 SPARQL queries');
            %resource_to_technique = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX ero: <http://purl.obolibrary.org/obo/>
PREFIX vivo: <http://vivoweb.org/ontology/core#>
select ?resource ?technique_label where {
?core a vivo:Laboratory .
?resource ?any_relationship ?core .
?resource ero:ERO_0000543 ?technique_uri .
?technique_uri rdfs:label ?technique_label
}', $sparql_url );
            DEBUG('    End 3.3 of 3 SPARQL queries');
        }

        my $num_cores_done  = 0;
        my $num_cores_to_do = scalar keys %core_to_rdf_url;

        foreach
            my $core_name ( sort { lc $a cmp lc $b } keys %core_to_rdf_url ) {
            $num_cores_done++;

            DEBUG("  Begin $num_cores_done of $num_cores_to_do cores");
            my $core_rdf_url = $core_to_rdf_url{$core_name};

            my $core_url = $provider_url->clone;
            $core_url->query_form( uri    => $core_rdf_url,
                                   format => 'application/xml' );
            my $request = HTTP::Request->new( GET => $core_url );
            my $response = $ua->request($request);
            unless ( $response->is_success ) {
                LOGDIE
                    "COULD NOT DOWNLOAD CORE $num_cores_done/$num_cores_to_do $core_name AT $core_url: ",
                    $response->status_line;
            }

            DEBUG("    End $num_cores_done of $num_cores_to_do cores");

            my $data = XMLin(
                  $response->content,
                  ForceArray => [
                        'staff', 'resource', 'affiliation', 'resources', 'links'
                  ],
                  KeyAttr   => '',
                  GroupTags => { affiliations => 'affiliation',
                                 staffs       => 'staff',
                                 links        => 'link',
                  }
            );

            my %coreinfo = (
                     core     => $data->{name},
                     location => $core_to_location{$core_rdf_url} || undef,
                     url      => eval { $data->{links}->[0]->{link}->{url} }
                         || $core_to_website{$core_rdf_url}
                         || undef,
                     organization => eval { $data->{affiliations}->[0]->{name} }
                         || '',
                     contact => eval { $data->{staffs}->[0]->{name} }   || '',
                     phone   => eval { $data->{staffs}->[-1]->{phone} } || '',
                     email   => eval { $data->{staffs}->[-1]->{email} } || '',
                     rdf_url => $core_rdf_url,
            );

            if ( $data->{all_resources} ) {

                foreach my $resource_group (
                                    @{ $data->{all_resources}->{resources} } ) {
                    my $group_name = $resource_group->{eiroot};
                    foreach my $resource ( @{ $resource_group->{resource} } ) {

                        # Example:
                        # name = "Awesome #2 pencil"
                        # type = "pencil" (subclass of "writing implement")
                        # technique = "writing"

                        my $name      = $resource->{name};
                        my $type      = $resource->{eitype};
                        my $permalink = $resource->{eiuri};
                        my $technique = $resource_to_technique{$permalink};

                        if ($technique) {
                            push @{ $coreinfo{resources}->{$technique} }, $name;
                        }
                        if ($type) {

                            # if its part of a service group, and it's
                            # already listed under a technique, no
                            # need to list under one of the fairly
                            # useless broad and shallow "service" type
                            # categories
                            unless (     $technique
                                     and $group_name =~ m/\bservice/i ) {

                                push @{ $coreinfo{resources}->{$type} }, $name;
                            }
                        }
                    }
                }
            }

            if ( exists $core_data{ $coreinfo{core} } ) {
                LOGWARN(
                    qq{Found multiple cores named "$coreinfo{core}" at $base_uri -- will only keep one}
                );
            } else {
                $core_data{ $coreinfo{core} } = \%coreinfo;
            }
        }

        DEBUG("  End download of data from $base_uri");
    }

    my $json   = JSON->new->allow_nonref;
    my $pretty = $json->pretty->encode( \%core_data );
    $pretty = encode_utf8($pretty);

    return $pretty;
}

###############################################################################

sub _get_sparql_data {
    my $sparql_query = shift;
    my $sparql_url   = shift;

    my $request = POST( $sparql_url,
                        [  query  => $sparql_query,
                           view   => 'published',
                           format => 'text/plain'
                        ]
    );

    my $response = $ua->request($request);
    if ( !$response->is_success ) {
        LOGDIE 'COULD NOT DOWNLOAD DATA VIA SPARQL INTERFACE: ',
            $request->as_string, "\nReponse was: ", $response->status_line;
    } elsif ( $response->content_type !~ m{^text/plain} ) {
        LOGDIE
            'SPARQL INTERFACE RETURNED RESULTS WITH INVALID CONTENT-TYPE "',
            $response->content_type,
            '" WHEN WE WERE EXPECTING "text/plain": ',
            $request->as_string;
    }

    my %data;
    my @rows = split /\n/, $response->content;
    shift @rows;    # ignore header column
    foreach my $row (@rows) {
        my %result;
        my @entries = split /\t/, $row;
        if ( defined $entries[1] ) {
            $entries[1] =~ s/^" (.*?) ".*$ /$1/x;
        }
        $data{ $entries[0] } = $entries[1];
    }

    return %data;
}

1;
