#!/usr/pkg/bin/perl

use warnings;
use strict;

use Test::More;

use XML::Feed;

sub test_feed {
	my ($old, $new) = @_;

	my @keys = qw(
		format
		title
		description
	);
	# OK if link is different
	# OK if modified is different
	# generator will be different

	for my $i (@keys) {
		is($new->$i(), $old->$i(), qq{$i is preserved});
	}
}

sub test_entries {
	my ($old, $new) = @_;
	my @old_entries = $old->entries();
	my @new_entries = $new->entries();
	is (@new_entries, @old_entries, q{same number of entries});
	for my $new_entry (@new_entries) {
		my $old_entry = shift @old_entries;

		my @keys = qw(
			title
			link
			id
			author
		);
		# Textpattern didn't put tags/category in feed
		# Textpattern didn't put modified in feed
		# XXX OK that issued appears off by five hours?

		for my $i (@keys) {
#			my $old_i = $old_entry->$i();
#			$old_i ||= 'undef';
#			my $new_i = $new_entry->$i();
#			$new_i ||= 'undef';
#
#			diag("old $i: $old_i");
#			diag("new $i: $new_i");
			is($new_entry->$i(), $old_entry->$i(), qq{same $i});
		}

		# seems to be blank
#		for my $c ($new_entry->summary()) {
#			my $d = $old_entry->summary();
#
#			my @summary_keys = qw(
#				body
#			);
#
#			for my $i (@summary_keys) {
#				is($c->$i(), $d->$i(), qq{same $i});
#			}
#		}

		# stymied by smart quotes
#		for my $c ($new_entry->content()) {
#			my $d = $old_entry->content();
#
#			my @content_keys = qw(
#				body
#			);
#
#			for my $i (@content_keys) {
#				is($c->$i(), $d->$i(), qq{same $i});
#			}
#		}

		for my $e ($new_entry->enclosure()) {
			my $f = $old_entry->enclosure();

			my @enclosure_keys = qw(
				type
				length
			);

			for my $i (@enclosure_keys) {
				is($e->$i(), $f->$i(), qq{same $i});
			}
		}
	}
}

my $old_rss = XML::Feed->parse('txp-limit-100.rss');
my $old_atom = XML::Feed->parse('txp-limit-100.atom');
my $new_rss = XML::Feed->parse('../www.schmonz.com/html/index.rss');
my $new_atom = XML::Feed->parse('../www.schmonz.com/html/index.atom');

test_feed($old_atom, $old_rss);
test_entries($old_atom, $old_rss);

test_feed($old_rss, $new_rss);
test_entries($old_rss, $new_rss);

test_feed($old_atom, $new_atom);
test_entries($old_atom, $new_atom);

done_testing();
