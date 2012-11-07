Plumage: Biomedical resource discovery for institutions, powered by Eagle-I

# About Plumage

Plumage is free software to make biomedical resources at large
institutions more discoverable. It was developed at the University of
California, San Francisco, to power [UCSF Cores Search], the
campus-wide search engine for core resources.

## Why Plumage?

Designed to maximize resource discoverability:

* typeahead search available on every page
* users can browse through a complete A-Z index of options, including synonyms

Carefully optimized for search engine users:

* every synonym for every concept has its own page
* page titles and content are tuned to meet needs of searchers
* pages include semantic data in microformats

Easy to deploy:

* pulls data from an eagle-i instance, or from a compatible data source (e.g. CSV file with Eagle-I ontology mappings)
* generates a static site, compatible with all web servers on all platforms

Designed for success:

* Learn more about Plumage's design strategy in the [UCSF Cores Search 2.0: Design Strategy Overview](slides) Slideshare presentation.


## Who is Plumage?

The Plumage software was developed by Anirvan Chatterjee and the
Virtual Home team at the [Clinical & Translational Science
Institute][CTSI] at the University of California, San Francisco, in
collaboration with UCSF's [Research Resources Program][RRP].

This project was supported by the National Center for Research
Resources and the National Center for Advancing Translational
Sciences, National Institutes of Health, through UCSF-CTSI Grant
Number UL1 RR024131. Its contents are solely the responsibility of the
authors and do not necessarily represent the official views of the
NIH.

## License

Plumage is Copyright (c) 2012, The Regents of the University of
California. All rights reserved.

This application is free software; you can redistribute it and/or
modify it under the terms of the BSD license (revised, three clause).
For more details, see the full text of the license in the file
LICENSE. (TLDRLegal offers a _non-binding_ [human-readable
description](TLDRLegal) of this license.)

### Bundled code

The default Plumage distribution is bundled with several other open
source projects:

* [Twitter Bootstrap], released under an [Apache 2.0 license]
* [Placeholders.js], released under an [MIT license]
* [Resize Events], released under the [GPL]

Plumage websites dynamically load [jQuery] and [html5shiv] JavaScript
libraries (both released under the [MIT license]). The software uses a
number of Perl [CPAN] modules during the build process, distributed
under several open source licenses, typically under the
[same terms][Perl license] as Perl itself.

# Technical documentation

Plumage is an application written in Perl 5.12, and tested on Linux
and MacOS. It extracts data from an instance of eagle-i (or data
marked up with the eagle-i ontology), and generates a new web site --
static HTML, JavaScript, and images that can be deployed on any
server.

The software is bundled with a standard set of web templates created
with Template Toolkit incorporating cores discoverability best
practices originally implemented at UCSF. Generated website can be
easily customized in two ways:

* Basic changes (e.g. to the name of the generated website) can be
  made in the plumage.conf configuration file.

* Many look and feel changes can be made by adding custom header and
  footer HTML, CSS, and JavaScript, to enhance or override the base
  templates. These customizations are stored in a way that allows for
  easy upgrades of the base templates.

## Quick start

Ensure you have Perl 5.12 or higher installed on your server. Perl
5.12+ is installed on virtually all current Unix-like distributions,
including MacOS 10.7 and higher. If you're unable to upgrade an older
version of Perl bundled with your system, use [Perlbrew] to install a
newer version of Perl. Plumage may work on Windows, but hasn't been
tested.

Download a [tarball] or [ZIP file] of Plumage from Github. Unarchive
it.

Install Plumage and its Perl dependencies. You may be prompted to
configure [CPAN] settings; if so, just follow the instructions, and
stick with the default options.

    perl Build.PL
    ./Build installdeps

Then try running the Plumage app.

    ./bin/plumage

If you see a help screen, everything worked.

Now we're going to configure the simplest possible configuration. Use
a text editor to create a file called `plumage.conf` in your current
directory with the following contents. (We're using Howard University
as an example.)

    site_name              = Howard Cores Search
    institution_short_name = Howard
    eagle_i_base_url       = http://howard.eagle-i.net/
    output_path            = /var/www/html/plumage_example
    url                    = http://localhost/plumage_example/

Here's how to set the configuration options:

* Set `site_name` to the name of the website you're creating.

* Set `institution_short_name` to however your users refer to your
  institution when running searches, e.g UCSF, Howard OHSU.

* Set `eagle_i_base_url` to the root URL of your eagle-i
  installation. If it's password protected, put the username and
  password in the URL, e.g
  `http://username:password@youreagle-i.server.url/`.

* The `output_path` is the place on disk where the new website will be
  written. **Create a new directory**, and enter the path here;
  Plumage will not run if this directory doesn't exist. *NOTE: Plumage
  will delete the contents of this directory** every time it runs.

* Set `url` to the URL where this website will be viewed. If you have
  a local web server, you might use an `http://localhost/` URL. If you
  don't, you can use a `file://` URL that corresponds with your
  `output_path`; if your `output_path` is `/tmp/plumage-test` you can
  set your URL to ``file:///tmp/plumage-test/`.

Done? Let's build the website:

    ./bin/plumage --build

You should see messages showing the website being built.

Pay attention to error messages. Still having problems? Feel free to
contact Anirvan (anirvan.chatterjee at ucsf.edu) with your questions.

## Real world usage

*to be written*

## Configuration details

### Required

`institution_short_name` to the most colloquial way your users refer
to your institution when running searches. For example, most users at
the University of California, San Francisco will write "UCSF" and are
likely to run web searches for things like "ucsf nmr".

`eagle_i_base_url` is the root URL of your eagle-i installation. If
your installation is centrally hosted, it might look like
http://yourname.eagle-i.net/. If it's password protected, you can
put the authentication details in the URL, e.g
http://username:password@youreagle-i.server.url/.

`output_path` is the place on disk where the new website will be
written. Create a new directory, and enter the path here; Plumage
builds will not run if this directory does not exist. **Important: The
contents of this directory will be overwritten on every build.**

`url` is the URL where the generated website will be viewed. If you
have a local web server, you might use an http://localhost/ URL. If
you don't, you can use a file:// URL that corresponds with your
output_path; if your output_path is /tmp/plumage-test you can
set your URL to file:///tmp/plumage-test/.

`template_path` -- to be documented

### Customizing look and feel

`custom_template_path` -- to be documented

### Upgrading the search engine

Plumage works out of the box with [Swiftype], a free search provider
(analogous to Google Custm Search, but more easily flexible, and free
for many users). Swiftype is optional, but highly recommended over the
minimal default typeahead search. Set up a new Swiftype account, and
an engine for every website for which you want to use Swiftype search.

For Swiftype to work, you need to set both an overall
swiftype_api_key and a swiftype_key for every website role.

`swiftype_api_key` is the private account-wide API key listed at
http://swiftype.com/user/edit

`swiftype_key` comes from the line that reads Swiftype.key = '...' on
the "Install Options" page of every Swiftype search engine. If you
have different versions of your content on main and dev servers,
you'll have to create two different Swiftype engines, each indexing
the different sections of your content, and need to ensure that
Swiftype's servers can index your dev server.

### Tracking usage

`google_analytics_id` is optional, and should be set to your new
site's Google Analytics account ID. It should look something like
UA-1234-5678. Make sure to create a new Google Anaytics account for
every Plumage instance you create. Example usage: if you have
cores.institution.edu, and dev-cores.institution.edu, set a Google
Analytics ID for the former role, and not the latter role.

### Deploy hook

`build_deploy_command` is an optional command line that gets run after
every Plumage site build. For example, you might want to run Plumage
on a staging server, and set build_deploy_command to rsync -avz -e ssh
--delete /where/files/should/get/written
user@cores.yoursite.edu:/final/output/location/ to push the contents
out to your live server.

[UCSF Cores Search]: http://cores.ucsf.edu/
[CTSI]: http://ctsi.ucsf.edu/
[RRP]: http://rrp.ucsf.edu/
[slides]: http://www.slideshare.net/CTSIatUCSF/ucsf-cores-search-20-design-strategy-overview
[TLDRLegal]: http://www.tldrlegal.com/license/bsd-3-clause-license-(revised)
[Twitter Bootstrap]: http://twitter.github.com/bootstrap/
[Placeholders.js]: https://github.com/jamesallardice/Placeholders.js
[Resize Events]: http://irama.org/web/dhtml/resize-events/
[jQuery]: http://jquery.com/
[html5shiv]: http://code.google.com/p/html5shiv/
[Apache 2.0 license]: http://www.apache.org/licenses/LICENSE-2.0
[GPL]: http://www.gnu.org/licenses/gpl.html
[MIT license]: http://opensource.org/licenses/mit-license.php
[Perl license]: http://dev.perl.org/licenses/
[tarball]: https://github.com/CTSIatUCSF/plumage/tarball/master
[ZIP file]: https://github.com/CTSIatUCSF/plumage/zipball/master
[Perlbrew]: http://perlbrew.pl/
[CPAN]: http://www.cpan.org/
[Swiftype]: http://swiftype.com/
