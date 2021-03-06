#!/usr/bin/perl

use Socket;
use POSIX;
use strict;
use Time::Piece;
use Time::HiRes qw(gettimeofday usleep);
$SIG{TERM} = sub { POSIX::_exit(0); };
our ($namespace, $pod, $container, $bytes_per_line, $bytes_per_io, $xfer_count, $processes, $delay_usecs, $xfer_time, $exit_at_end) = @ARGV;
sub timestamp($) {
    my ($str) = @_;
    my (@now) = gettimeofday();
    printf STDERR  "$container %s.%06d %s\n", gmtime($now[0])->strftime("%Y-%m-%dT%T"), $now[1], $str;
}
sub xtime() {
    my (@now) = gettimeofday();
    return $now[0] + ($now[1] / 1000000.0);
}
timestamp("Clusterbuster logger starting");

while ($processes-- > 0) {
    if ((my $child = fork()) == 0) {
	my $linebuf = "";
	for (my $i = 0; $i < $bytes_per_line; $i++) {
	    $linebuf .= 'A';
	}
	$linebuf .= "\n";
	my ($buffer);
	my ($bufsize) = 0;
	do {
	    $buffer .= $linebuf;
	    $bufsize += length $linebuf;
	} while ($bufsize < $bytes_per_io);
	my ($start_time) = xtime();
	my ($xfers) = 0;
	while (($xfer_time == 0 && $xfer_count == 0) ||
	       ($xfer_time > 0 && xtime() - ($start_time + $xfer_time) < 0) ||
	       ($xfer_count > 0 && $xfers++ < $xfer_count)) {
	    my ($bytes_left) = $bufsize;
	    while ($bytes_left > 0) {
		my ($answer) = syswrite(STDERR, $buffer, $bytes_left);
		if ($answer > 0) {
		    $bytes_left -= $answer;
		} else {
		    exit(1);
		}
	    }
	    if ($delay_usecs > 0) {
		usleep($delay_usecs);
	    }
	}
	if (! $exit_at_end) {
	    sleep;
	}
	exit(0);
    }
}

while ((my $child = wait()) >= 0) {
}
