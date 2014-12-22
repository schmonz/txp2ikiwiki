#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

use File::Temp qw(tempdir);

require_ok('bin/ikiwiki-import');

sub normalize_one {
	my ($sourcename, $nth_most_recent) = @_;

	throws_ok { IkiWiki::Import::Source->new('fnord') } qr|unknown source|;

	my $source = IkiWiki::Import::Source->new($sourcename);
	my $normalized_posts = IkiWiki::Import::NormalizedPosts->new($source);
	my $normalized_post = $normalized_posts->[$nth_most_recent];
	isa_ok($normalized_post, 'IkiWiki::Import::NormalizedPost');

	is(
		$normalized_post->{title},
		'When is refactoring a good decision?',
	);
	is(
		$normalized_post->{slug},
		'when-is-refactoring-a-good-decision',
	);
	is(
		$normalized_post->{creation_date},
		'2014-08-07 22:30:48',
	);
	is_deeply(
		$normalized_post->{tags},
		[qw(technology)],
	);
	like(
		$normalized_post->{body},
		qr|refactoring is likely a good decision when|,
	);
	like(
		$normalized_post->{body},
		qr|Gödel, Escher, Bach|,
	);
	like(
		$normalized_post->{body},
		qr|https://en.wikipedia.org/wiki/Gödel,_Escher,_Bach|,
	);
	like(
		$normalized_post->{body},
		qr|Øredev|,
	);
	unlike(
		$normalized_post->{body},
		qr|\r\n|,
	);

	return $normalized_post;
}

sub format_one {
	my ($normalized_post) = @_;

	my $formatted_post = IkiWiki::Import::FormattedPost->new(
		$normalized_post,
	);
	isa_ok($formatted_post, 'IkiWiki::Import::FormattedPost');

	my $post_content = $formatted_post->get_post();
	like($post_content,
		qr|^\[\[!meta title="When.+decision\?"\]\]$|m);
	like($post_content,
		qr|^\[\[!meta date="2014-08-07 22:30:48"\]\]$|m);
	like($post_content,
		qr|^\[\[!tag technology\]\]$|m);
	like($post_content,
		qr|refactoring is likely a good decision when|m);

	return $formatted_post;
}

sub serialize_one {
	my ($formatted_post) = @_;
	my $srcdir = get_tmpdir_for_test();

	my $serialized_post = IkiWiki::Import::SerializedPost->new(
		$formatted_post,
		$srcdir,
	);
	isa_ok($serialized_post, 'IkiWiki::Import::SerializedPost');

	my $expected_post = $serialized_post->get_post();
	ok(-f "$srcdir/$expected_post", qq{$expected_post exists});
	my $actual_contents = slurp_file("$srcdir/$expected_post");
	like($actual_contents, qr|refactoring is likely a good decision when|m);

	return $serialized_post;
}

sub main_populates_srcdir {
	can_ok('IkiWiki::Import', qw(main));

	my $tmpdir = get_tmpdir_for_test();
	my $srcdir = "$tmpdir/testsite/src";
	my $setupfile = "$tmpdir/ikiwiki.setup";

	ok(! -d $srcdir);
	ok(! -f $setupfile);
	lives_ok { IkiWiki::Import::main('textpattern', $srcdir, $setupfile) };
	ok(-d $srcdir);
	ok(-f $setupfile);
	cmp_ok(get_files_in_dir($srcdir), '>', 2000);
	my $setup = slurp_file($setupfile);
	like($setup, qr|^wikiname: Yareev's schmonz\.com|m);
	like($setup, qr|^url: www\.schmonz\.com|m);
}

sub dunno_much_about_history {
	my $reason =<<EOT;
ikiwiki-import was initially developed against a CMS that didn't
keep a history of changes. If you're importing from a system that
does, and you can arrange to roll back to the state of that system
at an arbitrary point in time, then the following procedure will
at least preserve changes in the order they occurred:

1. Initialize a repository using your preferred VCS
2. Reproduce the initial state of the source system
3. Run ikiwiki-import into `/tmp/ikiwiki-import`
4. Copy the contents of that directory into your repo checkout
5. Add and commit all
6. `rm -rf /tmp/ikiwiki-import`
7. Move the source system forward by one change
8. Goto (3) until there are no more changes

If you have a need for higher-fidelity metadata (or just a more
efficient process), direct support in ikiwiki-import for importing
change history would be welcome.
EOT
	pass($reason);
}

sub get_tmpdir_for_test {
	return tempdir(
		'ikiwiki-test-import.XXXXXXXXXX',
		DIR	=> File::Spec->tmpdir(),
		CLEANUP	=> 1,
	);
}

sub get_files_in_dir {
	my ($dir) = @_;
	opendir(my $dh, $dir) || die "can't opendir $dir: $!";
	my @non_dots = grep { ! /^\./ } readdir($dh);
	closedir $dh;

	return @non_dots;
}

sub slurp_file {
	my ($file) = @_;

	local $/ = undef;
	open(my $in, '<', $file) || die "can't open $file: $!";
	my $contents = <$in>;
	close($in) || die "can't close $file: $!";

	return $contents;
}

serialize_one(format_one(normalize_one('textpattern', 5)));
main_populates_srcdir();
dunno_much_about_history();
done_testing();
