#!/usr/bin/perl

package Plumage::Swiftype;
use 5.12.0;
use lib '.', '..', 'lib', '../lib';
use HTTP::Request::Common;
use JSON qw( decode_json );
use LWP::Protocol::https;
use LWP::Simple qw( get );
use LWP::UserAgent;
use Log::Log4perl qw(:easy);
use Plumage::Config qw( get_config );
use URI;
use open ':encoding(utf8)';
use strict;
use warnings;
binmode STDERR, ':utf8';
binmode STDOUT, ':utf8';

sub swiftype_reindex {

    my $config = get_config();

    unless ( $config->{swiftype_api_key} ) {
        DEBUG "No swiftype_api_key set, therefore not reindexing swiftype";
        return;
    }

    my $api_key = $config->{swiftype_api_key};

    state $ua = LWP::UserAgent->new;

    my $found_url_to_reindex = 0;
    my @supported_crawl_urls;

    my $engines_response = get(
          "https://api.swiftype.com/api/v1/engines.json?auth_token=$api_key");
    if ( $engines_response
         and my $engines_data = eval { decode_json($engines_response) } ) {
        foreach my $engine ( @{$engines_data} ) {
            my $domains_response
                = get(
                "https://api.swiftype.com/api/v1/engines/$engine->{slug}/domains.json?auth_token=$api_key"
                );
            if ( $domains_response
                 and my $domains_data
                 = eval { decode_json($domains_response) } ) {
                foreach my $domain ( @{$domains_data} ) {
                    my $crawl_url
                        = URI->new( $domain->{start_crawl_url} )->canonical;
                    push @supported_crawl_urls, $crawl_url;

                    if ( $config->{url}->eq($crawl_url) ) {
                        $found_url_to_reindex = 1;
                        my $response
                            = $ua->request( PUT
                            "https://api.swiftype.com/api/v1/engines/$engine->{slug}/domains/$domain->{id}/recrawl.json?auth_token=$api_key"
                            );
                        if ( $response->is_success ) {
                            INFO("Swiftype is now reindexing $crawl_url");
                        } else {
                            my $message_data
                                = eval { decode_json( $response->content ) };
                            if ( $message_data and $message_data->{error} ) {
                                WARN(
                                    "[Optional] manual Swiftype reindex of $crawl_url failed -- '$message_data->{error}'"
                                );
                            } else {
                                WARN(
                                    "[Optional] manual Swiftype reindex of $crawl_url failed"
                                );
                            }
                        }
                    }
                }

                unless ($found_url_to_reindex) {
                    WARN(
                        "Tried to ask Swiftype to reindex $config->{url} but Swiftype hasn't seen that exact domain URL before (though it HAD seen: ",
                        join( ', ', @supported_crawl_urls ),
                        ") -- make sure that at least you have the URL set in your Plumage configuration file also added to Swiftype"
                    );
                }

            } else {
                ERROR(
                    "[Optional] manual Swiftype reindex failed -- could not access Swiftype list of domains for search engine '$engine->{slug}'"
                );
            }
        }
    } else {
        WARN(
            "[Optional] manual Swiftype reindex failed -- could not access Swiftype list of search engines, for reindex"
        );
    }

    return 1;
}

1;
