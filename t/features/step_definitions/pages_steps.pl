#!/usr/pkg/bin/perl

use warnings;
use strict;

use Test::BDD::Cucumber::StepFile;

use Test::WWW::Mechanize;
use Test::More;

Given qr/Amitai's production website/, sub {
	S->{baseurl} = 'http://www.schmonz.com';
};

Given qr/a browser/, sub {
	S->{browser} = Test::WWW::Mechanize->new();
};

When qr/request a single article/, sub {
	S->{browser}->get_ok(S->{baseurl} . '/2014/01/28/on-some-cusps');
};

Then qr/has the sidebar/, sub {
	S->{browser}->content_contains('<h5>About Me</h5>');
	S->{browser}->content_contains('<h5>Greatest Hits</h5>');
	S->{browser}->content_contains('<h5>Search</h5>');
};

Then qr/exactly one wordcount/, sub {
	my $html_content = S->{browser}->content();
	my @wordcounts = $html_content =~ /(<h4 class="words article_atts">[0-9]+ words<\/h4>)/g;
	is(scalar @wordcounts, 1);
};

Then qr/title matches the slug/, sub {
	S->{browser}->title_is(q{Yareev's schmonz.com: On some cusps});
	S->{browser}->content_like(qr/<h3 class="article_title">.+cusps.+<\/h3>/);
};

Then qr/posted date matches the slug/, sub {
	S->{browser}->text_contains('2014-01-28');
	S->{browser}->content_contains('<h4 class="posted_date article_atts">2014-01-28 ');
};

Then qr/body content is there/, sub {
	S->{browser}->text_contains(q{I became willing to plus it});
};
