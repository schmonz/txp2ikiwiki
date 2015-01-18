#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use Test::More;
use Test::Exception;

use File::Temp qw(tempdir);

require_ok('bin/ikiwiki-import');

my %local_mysql = (
	dbname => 'schmonz_textpattern',
	user => 'schmonz',
	password => '',
);

sub normalize_one {
	my ($sourcename, $nth_most_recent) = @_;

	throws_ok { IkiWiki::Import::Source->new('fnord') } qr|unknown source|;

	my $source = IkiWiki::Import::Source->new($sourcename, %local_mysql);
	isa_ok($source, 'IkiWiki::Import::Source');
	isa_ok($source, 'IkiWiki::Import::Source::Textpattern');

	my $config = IkiWiki::Import::Config->new($source);
	isa_ok($config, 'IkiWiki::Import::Config');

	my $normalized_posts = IkiWiki::Import::NormalizedPosts->new($source);
	my $normalized_post = $normalized_posts->[$nth_most_recent];
	isa_ok($normalized_post, 'IkiWiki::Import::NormalizedPost');

	my %required_fields = (
		id			=> '',
		visible			=> '',
		title			=> '',
		author_name		=> '',
		author_email		=> '',
		creation_date		=> '',
		modification_date	=> '',
#		expiration_date		=> '',
		url_slug		=> '',
		tags			=> 'ARRAY',
		text_format		=> '',
#		text_encoding		=> '',
		excerpt			=> '',
		body			=> '',
	);

	for my $field (keys %required_fields) {
		my $value = $normalized_post->{$field};
		isnt($value, undef, qq{defined $field});
		my $type = ref($value);
		my $expected_type = $required_fields{$field};
		is($type, $expected_type, qq{sensible $field});
	}

	is($normalized_post->{title}, 'When is refactoring a good decision?');
	is($normalized_post->{creation_date}, '2014-08-07 22:30:48');
	is($normalized_post->{url_slug}, 'when-is-refactoring-a-good-decision');
	is_deeply($normalized_post->{tags}, [qw(technology)]);

	my $body = $normalized_post->{body};
	like($body, qr|refactoring is likely a good decision when|);
	like($body, qr|Øredev|);
	like($body, qr|Gödel, Escher, Bach|);
	like($body, qr|https://en.wikipedia.org/wiki/Gödel,_Escher,_Bach|);
	unlike($body, qr|\r\n|);

	return ($normalized_post, $config);
}

sub format_one {
	my ($normalized_post, $config) = @_;

	my $formatted_post = IkiWiki::Import::FormattedPost->new(
		$normalized_post,
	);
	isa_ok($formatted_post, 'IkiWiki::Import::FormattedPost');

	my @lines = split(/\n/m, $formatted_post->get_post());

	like(shift @lines, qr|^\[\[!meta title=".+"\]\]$|);
	like(shift @lines, qr|^\[\[!meta date=".+"\]\]$|);
	like(shift @lines, qr|^\[\[!meta updated=".+"\]\]$|);
	like(shift @lines, qr|^\[\[!tag |);
	like(shift @lines, qr|^$|);

	my $body = join("\n", @lines);
	like($body, qr|refactoring is likely a good decision when|m);

	return ($formatted_post, $config);
}

sub serialize_one {
	my ($formatted_post, $config) = @_;
	my $srcdir = get_tmpdir_for_test();

	my $serialized_post = IkiWiki::Import::SerializedPost->new(
		$formatted_post,
		$srcdir,
		$config,
		0,
	);
	isa_ok($serialized_post, 'IkiWiki::Import::SerializedPost');

	my $expected_post = $serialized_post->get_post();
	is($expected_post, '2014/08/07/when-is-refactoring-a-good-decision.txtl');
	ok(-f "$srcdir/$expected_post", qq{$expected_post exists});
	my $actual_contents = slurp_file("$srcdir/$expected_post");
	like($actual_contents, qr|refactoring is likely a good decision when|m);

	return ($serialized_post, $config);
}

sub main_populates_srcdir {
	can_ok('IkiWiki::Import', qw(main));

	my $tmpdir = get_tmpdir_for_test();
	my $srcdir = "$tmpdir/testsite/src";
	my $setupfile = "$tmpdir/ikiwiki.setup";

	ok(! -d $srcdir);
	ok(! -f $setupfile);
	lives_ok { IkiWiki::Import::main($srcdir, $setupfile, 'textpattern',
		%local_mysql) };
	ok(-d $srcdir);
	ok(-f $setupfile);
	my $setup = slurp_file($setupfile);
	like($setup, qr|^wikiname: Yareev's schmonz\.com|m);
	like($setup, qr|^url: www\.schmonz\.com|m);

	return $srcdir;
}

sub generate_destdir {
	my ($srcdir, $destdir) = @_;
	# XXX really want $setupfile filled in with srcdir and destdir
	my $command = 'ikiwiki';
	$command .= ' -plugin textile';
	$command .= ' -plugin tag';
	$command .= ' -plugin comments';
	$command .= ' -set comments_pagespec="*"';
	$command .= ' -set comments_allowauthor=1';
	$command .= ' -set allow_symlinks_before_srcdir=1';
	$command .= ' -verbose';
	$command .= " $srcdir $destdir";
	diag("about to run $command");
	ok(! system($command));
	diag("look in $destdir"); sleep 10;
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

sub slurp_file {
	my ($file) = @_;

	local $/ = undef;
	open(my $in, '<', $file) || die "can't open $file: $!";
	my $contents = <$in>;
	close($in) || die "can't close $file: $!";

	return $contents;
}

serialize_one(format_one(normalize_one('textpattern', 5)));
my $srcdir = main_populates_srcdir();
#generate_destdir($srcdir, get_tmpdir_for_test());
dunno_much_about_history();
done_testing();
