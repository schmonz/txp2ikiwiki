#!/usr/pkg/bin/perl

use warnings;
use strict;

use Test::More tests => 10;

use Test::BDD::Cucumber::StepFile;
use Test::WWW::Mechanize;
use Method::Signatures;

Given qr/the site's base URL "(.+)"/, func ($c) {
	$c->stash->{scenario}->{baseurl} = $1;
	$c->stash->{scenario}->{baseurl} =~ s|/$||;
};

Given qr/a web browser/, func ($c) {
	$c->stash->{scenario}->{browser} = Test::WWW::Mechanize->new();
};

When qr/I request the typical article "(.+)"/, func ($c) {
	$c->stash->{scenario}->{browser}->get_ok(
		$c->stash->{scenario}->{baseurl} . $1
	);
};

Then qr/the posted date is "(.+)"/, func ($c) {
	$c->stash->{scenario}->{browser}->text_contains($1);
};

Then qr/the title ends with "(.+)"/, func ($c) {
	$c->stash->{scenario}->{browser}->title_like(qr/: $1$/);
};

Then qr/the body contains "(.+)"/, func ($c) {
	$c->stash->{scenario}->{browser}->text_contains($1);
};
