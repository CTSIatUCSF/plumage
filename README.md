Plumage: Biomedical resource discovery for institutions, powered by Eagle-I

# 1. About Plumage

Plumage is free software to make biomedical resources at large
institutions more discoverable. It was developed at the University of
California, San Francisco, to power [UCSF Cores Search], the
campus-wide search engine for core resources.

## 1.1 Why Plumage?

Designed to maximize resource discoverability:

* typeahead search available on every page
* users can browse through a complete A-Z index of options, including synonyms
* works on cell phones, tablets, and desktop computers

Carefully optimized for search engine users:

* every synonym for every concept has its own page
* pages include semantic data via HTML5 + Schema.org microdata
* page titles and content are tuned to meet needs of searchers

Easy to deploy:

* pulls data from eagle-i, or from a compatible data source (e.g. CSV file with eagle-i ontology mappings)
* generates a static site, compatible with all web servers on all platforms

Designed for success:

* learn about Plumage's design strategy in the [UCSF Cores Search 2.0: Design Strategy Overview](slides) Slideshare presentation.


## 1.2 Who is Plumage?

The Plumage software was developed by Anirvan Chatterjee and the
Virtual Home team at the [Clinical & Translational Science
Institute][CTSI] at the University of California, San Francisco, in
collaboration with UCSF's [Research Resources Program][RRP]. This
project was supported by the National Center for Research Resources
and the National Center for Advancing Translational Sciences, National
Institutes of Health, through UCSF-CTSI Grant Numbers UL1 RR024131 and
UL1 TR000004. Its contents are solely the responsibility of the
authors and do not necessarily represent the official views of the
NIH.

## 1.3 License

Plumage is Copyright (c) 2012-2013, The Regents of the University of
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

# 2. Technical Overview

Plumage is an application written in Perl 5.12, and tested on Linux
and MacOS. It extracts data from an instance of eagle-i (or data
marked up with the eagle-i ontology), and generates a new web site: a
bundle of static HTML, JavaScript, and images that can be deployed on
any server.

The software is bundled with a standard set of modern HTML5 web
templates created with Template Toolkit, and incorporating cores
discoverability best practices originally implemented at UCSF.
Generated website can be easily customized in two ways:

* Basic changes (e.g. to the name of the generated website) can be
  made in the plumage.conf configuration file.

* Many look and feel changes can be made by adding custom header and
  footer HTML, CSS, and JavaScript, to enhance or override the base
  templates. These customizations are stored in a way that allows for
  easy upgrades of the Plumage code and base templates.

# 3. Quick Start Guide

This quick start guide is intended to help technical users with an
existing eagle-i installation get up and running with Plumage in
minutes.

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
hit return to stick with the default options.

    perl Build.PL
    PERL_MM_USE_DEFAULT=1 ./Build installdeps
    # if previous line doesn't work, use only "./Build installdeps"

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
    template_path          = /home/webmaster/plumage/templates
    output_path            = /var/www/html/plumage_example
    url                    = http://localhost/plumage_example/

Here's how to set the configuration options:

* Set `site_name` to the name of the website you're creating. For
  example, UCSF calls its Plumage site "UCSF Cores Search".

* Set `institution_short_name` to however your users refer to your
  institution when running searches. For example, users at the
  University of California, San Francisco are likely to run web
  searches for things like "ucsf nmr" therefore this is set to "UCSF".

* Set `eagle_i_base_url` to the root URL of your eagle-i installation.
  If your installation is centrally hosted, it might look like
  `http://yourname.eagle-i.net/`. If it's password protected, you can
  put the authentication details in the URL, e.g
  `http://username:password@youreagle-i.server.url/`.

* Set `template_path` to the full path to the `templates` directory
  that comes with this distribution (or a copy thereof). If you don't
  set this, Plumage will try looking in your current directory for a
  `templates` folder.

* The `output_path` is the place on disk where the new website will be
  written. **Create a new directory**, and enter the path here;
  Plumage will not run if this directory doesn't exist. **Plumage will
  delete and regenerate the contents of this directory every time it
  runs.**

* Set `url` to the URL where this website will be viewed. If you have
  a local web server, you might use an `http://localhost/` URL. If you
  want to put this on a subdirectory of your dev server you could set
  it to `http://dev.yoursite.edu/cores/`. If you want to use it
  offline, you can use a `file://` URL that corresponds with your
  `output_path` (if your `output_path` is `/tmp/plumage-test` try
  setting your URL to ``file:///tmp/plumage-test/`).

Done? Let's build the website:

    ./bin/plumage --build

You should see messages showing the website being built.

Pay attention to error messages. Still having problems? Feel free to
contact Anirvan (anirvan.chatterjee at ucsf.edu) with your questions.

If all goes well, your fancy new Plumage website will be written to
`output_path` and you'll be able to view it in a web browser at `url`.

# 4. Real World Usage

The quick start guide left you with a reasonably clean and generic
installation of Plumage. Now we're going to customize Plumage to meet
your needs.

## 4.1 Using Roles [IMPORTANT]

*to be written*

## 4.2 Customizing Look and Feel [IMPORTANT]

Almost every institution will want to customize the look and feel of
Plumage to match your local branding needs. Plumage is designed to
make it incredibly easy to make local look and feel changes without
needing to tweak the default templates, so you can take advantage of
upgraded default templates without losing your local changes.

The default templates are stored in the directory specified in
`template_path`. We suggest that you _don't_ edit these templates at
all.

Instead, **create a new directory for your custom local edits**, and
put the path in your configuration file as `custom_template_path`. For
example:

    template_path          = /home/webmaster/plumage/templates
    custom_template_path   = /home/webmaster/plumage/custom_templates

When Plumage is looking for templates, it'll look first in
`custom_template_path`, and only then in `template_path`. So if you
wanted to override a default template, just copy it to
`custom_template_path`, make some tweaks and it'll override the
default. But most of the time, you don't even need to do that. Look at
the HOWTOs below.

### Static and Dynamic Content

*actual documentation to be written*

### How Templates Work

All site templates are written using [Template Toolkit], a popular and
very well-documented templating system for Perl, sort of like PHP's
Smarty or Ruby's ERB.

*actual documentation to be written*

### How Bootstrap Works

All HTML and CSS on the site is written using [Twitter Bootstrap], a
popular responsive HTML5/CSS framework. Go read the Bootstrap
documentation. You will be confused if you don't.

*actual documentation to be written*

### HOWTO: Add Custom CSS

1. Configure a `custom_template_path` directory
2. Create a new file at `static/assets/css/custom.css` inside the directory
3. Put your CSS there
4. The contents of this file will be read _after_ the default Plumage CSS, which means it should override CSS rules of equal [CSS specificity] (if needed, you can make your CSS more specific or use `!important` for added weight)

### HOWTO: Add a Custom Institutional Navbar

1. Configure a `custom_template_path` directory
2. Create a new file called `custom_navbar_top.html.tt` inside the directory
3. Put content there (preferably inside `<div id="leaderboard" class="row"><div class="span12">`)
4. The contents of this file will be automatically included above the Plumage menu in the defaultpage header template (`_header.html.tt`)
5. If needed, add custom CSS styles to #leaderboard as described above

### HOWTO: Customize the Footer

1. Configure a `custom_template_path` directory
2. Create a new file called `custom_footer.html.tt` inside the directory
3. Put content there, inside one or more `<div class="row">` blocks
4. The content of this file will be automatically included in the default footer template (`_footer.html.tt`)
5. If needed, add custom CSS styles to the contents of #footer as described above

### HOWTO: Change the Contents of the About Page

1. Configure a `custom_template_path` directory
2. Create a new file called `custom_about_page.html.tt` inside the directory
3. Put content there (e.g. `<h2>`s and `<p>`s)
4. The content of this file will be automatically included in the default About page template (`about.html.tt`)

## 4.3 Upgrading the Search Engine via Swiftype

Plumage comes packaged with a minimal typeahead search, but we
recommend plugging in a professional hosted search system.

Plumage works out of the box with [Swiftype], a free search provider
(like Google Custom Search, but more flexible, and free for most
users). Swiftype is optional, but *very highly recommended*. Set up a
new Swiftype account, and an engine for every website for which you
want to use Swiftype search.

For Swiftype to work, you need to configure both an overall
`swiftype_api_key` and a `swiftype_key` for every website role.

* `swiftype_api_key` is the private account-wide API key listed at
  http://swiftype.com/user/edit

* `swiftype_key` comes from the line that reads Swiftype.key = '...'
  on the "Install Options" page of every Swiftype search engine. If
  you have different versions of your content on main and dev servers,
  you'll have to create two different Swiftype engines, each indexing
  the different sections of your content, and need to ensure that
  Swiftype's servers can index your dev server.

Every time you do a new build, Plumage will contact Swiftype's
servers, and use your API keys to kick off a reindex of your content.
(Swiftype may not reindex as frequently as you'd like; check their
documentation for details.)

## 4.4 Tracking Usage via Google Analytics

Plumage comes with support for Google Analytics out of the box, just
by adding one line to the configuration file. Start off by creating a
new Google Analytics account for your Plumage instance.

Then in the configuration file, set `google_analytics_id` to your new
site's Google Analytics account ID, e.g.:

    google_analytics_id = UA-1234567-01

Make sure to create a new Google Analytics account for every
*production* Plumage instance you create. For example, if you have a
production cores.institution.edu and a development
dev-cores.institution.edu, set a Google Analytics ID only for the
production role, like this:

    [production]
    url = http://cores.yoursite.edu/
    google_analytics_id = UA-1234567-01

    [dev]
    url = http://dev-cores.yoursite.edu/

### Tracking Swiftype usage

*to be written*

## 4.5 Ensuring Search Engine Visibility of All Pages

Plumage automatically creates a [sitemap], and lists the location via
[robots.txt][sitemap in robots.txt] file. But search
engines will only discover `robots.txt` if a Plumage site is installed
at the top level of your site (e.g. `http://cores.institution.edu/`
works, but `http://www.institution.edu/cores/` doesn't).

If you've put Plumage in a subdirectory (e.g.
`http://www.institution.edu/cores/`) and want maximum search engine
visibility, you have two choices:

1. If you're using an automated process to build a sitemap for your
whole site, make sure that automatic process picks up every `.html`
generated by Plumage.

2. Otherwise, make sure to add the sitemap URL to your site-wide
`robots.txt`. For example, if you've deployed your site at
`http://www.institution.edu/cores/`, add the line `Sitemap:
http://www.institution.edu/cores/assets/sitemap.xml` inside
`http://www.institution.edu/robots.txt`. (You can do this even
if you have a [preexisting sitemap listed][Multiple sitemaps in robots.txt]
there.)

## 4.6 Managing Deployments

`build_deploy_command` is an optional command line that gets run after
every Plumage site build. You can use this to create a deploy hook on
specific roles.

For example, you might want to run Plumage on a staging server, and
use rsync to copy the final production files to a live production
server.

    [production]
    url = http://cores.yoursite.edu/
    output_path = /var/www/html/cores-prod/
    build_deploy_command = rsync -avz -e ssh --delete /var/www/html/cores-prod/ user@cores.yoursite.edu:/var/www/html/

    [dev]
    url = http://dev-cores.yoursite.edu/
    output_path = /var/www/html/cores-dev/

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
[CSS specificity]: http://www.htmldog.com/guides/cssadvanced/specificity/
[Template Toolkit]: http://template-toolkit.org/
[sitemap]: https://support.google.com/webmasters/bin/answer.py?hl=en&answer=156184
[sitemap in robots.txt]: https://support.google.com/webmasters/bin/answer.py?hl=en&answer=183669
[Multiple sitemaps in robots.txt]: http://stackoverflow.com/questions/2594179/multiple-sitemap-entries-in-robots-txt
