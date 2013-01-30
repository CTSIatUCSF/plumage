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

    my $base_uri_text = shift;
    unless ($base_uri_text) {
        eval q{
	    use Plumage::Config qw( get_config );
	    my $config = get_config();
	    $base_uri_text = $config->{eagle_i_base_url};
	};
    }

    my $base_uri = URI->new($base_uri_text)
        || LOGCROAK
        qq{Invalid base URI "$base_uri_text", expected something more like "http://example.eagle-i.net/" or "https://eaglei.example.com/"};
    $base_uri = $base_uri->canonical;

    $ua ||= LWP::UserAgent::Determined->new;
    push @{ $ua->requests_redirectable }, 'POST';
    $ua->timing('5,5,5,5,5,5');
    $ua->ssl_opts( verify_hostname => 0 );

    my $cores_list_url = $base_uri->clone;
    $cores_list_url->path('/sweet/cores/');
    $cores_list_url->query_form( format => 'application/xml' );

    my $sparql_url = $base_uri->clone;
    if ( head("${base_uri}sparqler/") ) {
        $sparql_url->path('/sparqler/sparql');
    } else {
        $sparql_url->path('/repository/sparql');
    }

    my $provider_url = $base_uri->clone;
    $provider_url->path('/sweet/provider');

    INFO("Downloading data from $base_uri");

    my %core_data;

    my %core_to_rdf_url;
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

    DEBUG('  Begin 1 of 3 SPARQL queries');
    my %core_to_website = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
select ?core ?website where {
?core a ero:ERO_0000002 .
?core ero:ERO_0000480 ?website .
}
', $sparql_url );
    DEBUG('    End 1 of 3 SPARQL queries');

    DEBUG('  Begin 2 of 3 SPARQL queries');
    my %core_to_location = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
select ?core ?address where {
?core a ero:ERO_0000002 .
?core ero:ERO_0000055 ?address .
}
', $sparql_url );
    DEBUG('    End 2 of 3 SPARQL queries');

    unless (%core_to_location) {
        DEBUG('  Begin 2.1 of 3 SPARQL queries');
        %core_to_location = _get_sparql_data( '
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX ero: <http://purl.obolibrary.org/obo/>
PREFIX vivo: <http://vivoweb.org/ontology/core#>
select ?core ?address where {
?core a vivo:CoreLaboratory .
?core ero:ERO_0000055 ?address .
}
', $sparql_url );
        DEBUG('    End 2.1 of 3 SPARQL queries');
    }

    DEBUG('  Begin 3 of 3 SPARQL queries');
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
    DEBUG('    End 3 of 3 SPARQL queries');

    unless (%resource_to_technique) {
        DEBUG('  Begin 3.1 of 3 SPARQL queries');
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
        DEBUG('    End 3.1 of 3 SPARQL queries');
    }

    my $num_cores_done  = 0;
    my $num_cores_to_do = scalar keys %core_to_rdf_url;

    foreach my $core_name ( sort { lc $a cmp lc $b } keys %core_to_rdf_url ) {
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
             ForceArray =>
                 [ 'staff', 'resource', 'affiliation', 'resources', 'links' ],
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
            organization => eval { $data->{affiliations}->[0]->{name} } || '',
            contact      => eval { $data->{staffs}->[0]->{name} }       || '',
            phone        => eval { $data->{staffs}->[-1]->{phone} }     || '',
            email        => eval { $data->{staffs}->[-1]->{email} }     || '',
            rdf_url => $core_rdf_url,
        );

        if ( $data->{all_resources} ) {

            foreach my $resource_group (
                                  @{ $data->{all_resources}->{resources} } ) {
                my $group_name = $resource_group->{eiroot};
                foreach my $resource ( @{ $resource_group->{resource} } ) {
                    my $name      = $resource->{name};
                    my $type      = $resource->{eitype};
                    my $permalink = $resource->{eiuri};
                    my $technique = $resource_to_technique{$permalink};

                    if ( $group_name =~ m/\bservice/i ) {
                        if ($technique) {
                            push @{ $coreinfo{resources}->{$technique} },
                                $name;
                        }
                    } else {
                        if ($type) {
                            push @{ $coreinfo{resources}->{$type} }, $name;
                        }
                        if ($technique) {
                            push @{ $coreinfo{resources}->{$technique} },
                                $name;
                        }
                    }
                }
            }
        }

        $core_data{ $coreinfo{core} } = \%coreinfo;
    }

    DEBUG("  End download of data from $base_uri");

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
