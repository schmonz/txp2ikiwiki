#!/usr/pkg/bin/perl

use warnings;
use strict;

use Test::More tests => 10;
use Test::BDD::Cucumber::StepFile;

use Test::WWW::Mechanize;

Given qr/the site's base URL "(.+)"/, sub {
	S->{baseurl} = $1;
	S->{baseurl} =~ s|/$||;
};

Given qr/a web browser/, sub {
	S->{browser} = Test::WWW::Mechanize->new();
};

When qr/I request the typical article "(.+)"/, sub {
	S->{browser}->get_ok(
		S->{baseurl} . $1
	);
};

Then qr/the posted date is "(.+)"/, sub {
	S->{browser}->text_contains($1);
};

Then qr/the title ends with "(.+)"/, sub {
	S->{browser}->title_like(qr/: $1$/);
};

Then qr/the body contains "(.+)"/, sub {
	S->{browser}->text_contains($1);
};
