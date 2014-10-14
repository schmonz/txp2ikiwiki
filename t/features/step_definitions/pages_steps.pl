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

When qr/request the main index/, sub {
	S->{browser}->get_ok(S->{baseurl} . '/');
};

Then qr/has the sidebar/, sub {
	S->{browser}->content_contains('<h5>About Me</h5>');
	S->{browser}->content_contains('<h5>Greatest Hits</h5>');
	S->{browser}->content_contains('<h5>Search</h5>');
};

Then qr/exactly one wordcount/, sub {
	is(count_the_wordcounts(S->{browser}->content()), 1);
};

Then qr/has five wordcounts/, sub {
	is(count_the_wordcounts(S->{browser}->content()), 5);
};

sub count_the_wordcounts {
	my ($html_content) = @_;
	my @wordcounts = $html_content =~ /(<h4 class="words article_atts">[0-9]+ words<\/h4>)/g;
	return scalar @wordcounts;
}

Then qr/title matches the slug/, sub {
	S->{browser}->title_is(q{Yareev's schmonz.com: On some cusps});
	S->{browser}->content_like(qr/<h3 class="article_title">.+cusps.+<\/h3>/);
};

Then qr/title matches the site title/, sub {
	S->{browser}->title_is(q{Yareev's schmonz.com});
};

Then qr/has five article titles/, sub {
	S->{browser}->content_like(qr/<h3 class="article_title">.+<\/h3>/);
};

Then qr/posted date matches the slug/, sub {
	S->{browser}->content_contains('<h4 class="posted_date article_atts">2014-01-28 ');
};

Then qr/has five posted dates/, sub {
	S->{browser}->content_like(qr/<h4 class="posted_date article_atts">[0-9]{4}-[0-9]{2}-[0-9]{2} /);
};

Then qr/body content is there/, sub {
	S->{browser}->text_contains(q{I became willing to plus it});
};
