#!/usr/bin/perl

# test with
# sudo LD_LIBRARY_PATH=<prefix>/lib PERL5LIB=<PREFIX>/lib/perl perl ./swig/perl/xwiimote_test.pl

use xwiimote;
use IO::Poll qw(POLLIN);
use Time::HiRes qw(usleep);
use POSIX;

# display a constant
print "=== " . $xwiimote::NAME_CORE . " ===\n";

# list wiimotes and remember the first one
eval {
    $mon = new xwiimote::monitor(1, 1);
    print "mon fd = " . $mon->get_fd(0) . "\n";
    $ent = $mon->poll();
    $firstwiimote = $ent;
    while(defined($ent)) {
	print "Found device: " . $ent ."\n";
	$ent = $mon->poll();
    }
};
if($@) {
    print "ooops, cannot create monitor (" . $@ . ")\n";
}

# continue only if there is a wiimote
if (!defined($firstwiimote)) {
    print "No wiimote to read\n";
    exit(0);
}

# create a new iface
eval {
    $dev = new xwiimote::iface($firstwiimote);
};

if($@) {
    print "ooops (" . $@ . ")\n";
    exit(1);
}

# display some information and open the iface
eval {
    print "syspath: " . $dev->get_syspath() . "\n";
    $fd = $dev->get_fd();
    print "fd: " . $fd . "\n";
    print "opened mask: " . $dev->opened() . "\n";
    $dev->open($dev->available() | $xwiimote::IFACE_WRITABLE);
    print "opened mask: " . $dev->opened() . "\n";

    #$dev->rumble(1);
    #usleep(1000000/3);
    #$dev->rumble(0);
    $dev->set_led(1, 1);
    if($dev->get_devtype() != "balanceboard") {
        $dev->set_led(2, $dev->get_led(3));
        $dev->set_led(3, $dev->get_led(4));
        $dev->set_led(4, !$dev->get_led(4));
    }

    print "capacity: "  . $dev->get_battery()   . "%\n";
    print "devtype: "   . $dev->get_devtype()   . "\n";
    print "extension: " . $dev->get_extension() . "\n";
};

if($@) {
    print "ooops (" . $@ . ")\n";
    exit(1);
}

# read some values
$p = IO::Poll->new();

$stdin = new IO::Handle;
$stdin->fdopen(fileno(STDIN), "r");
$fdh = IO::Handle->new_from_fd($fd, "r");

$p->mask($stdin => POLLIN);
$p->mask($fdh   => POLLIN);
$evt = new xwiimote::event();

$n = 0;

while($n < 2) {
    $p->poll();

    eval {
	$dev->dispatch($evt);

	if($evt->{type} == $xwiimote::EVENT_KEY) {
	    ($code, $state) = $evt->get_key();
	    print "Key: " . $code . ", State: " . $state . "\n";
	    $n++;
	} elsif($evt->{type} == $xwiimote::EVENT_GONE) {
	    print "Gone\n";
	    $n = 2;
	} elsif($evt->{type} == $xwiimote::EVENT_WATCH) {
	    print "Watch\n";
	} elsif($evt->{type} == $xwiimote::EVENT_CLASSIC_CONTROLLER_KEY) {
	    ($code, $state) = $evt->get_key();
	    print "Classical controller key: " . $code . "x" . $state . "\n";
	    ($tv_sec, $tv_usec) = $evt->get_time();
	    print $tv_sec . " " . $tv_usec . "\n";
	    $evt->set_key($xwiimote::KEY_HOME, 1);
	    ($code, $state) = $evt->get_key();
	    print "Classical controller key: " . $code . "x" . $state . "\n";
	    $evt->set_time(0, 0);
	    ($tv_sec, $tv_usec) = $evt->get_time();
	    print $tv_sec . " " . $tv_usec . "\n";
	} elsif($evt->{type} == $xwiimote::EVENT_CLASSIC_CONTROLLER_MOVE) {
	    ($x, $y, $z) = $evt->get_abs(0);
	    print "Classical controller move 1: ", $x . " " . $y . "\n";
            $evt->set_abs(0, 1, 2, 3);
	    ($x, $y, $z) = $evt->get_abs(0);
	    print "Classical controller move 1: ", $x . " " . $y . "\n";
	    ($x, $y, $z) = $evt->get_abs(1);
	    print "Classical controller move 2: ", $x . " " . $y . "\n";
	} elsif($evt->{type} == $xwiimote::EVENT_IR) {
	    $i = 0;
	    while($i <= 3) {
	    	if($evt->ir_is_valid($i)) {
	    	    ($x, $y, $z) = $evt->get_abs($i);
		    print "IR ".$i." ".$x." ".$y." ".$z."\n";
	    	}
		$i++;
	    }
        } elsif($evt->{type} == $xwiimote::EVENT_BALANCE_BOARD) {
            ($tr, undef, undef) = $evt->get_abs(0);
            ($br, undef, undef) = $evt->get_abs(1);
            ($tl, undef, undef) = $evt->get_abs(2);
            ($bl, undef, undef) = $evt->get_abs(3);
            $tot = $tr + $br + $tl + $bl;
            # Top Left, Top Right, Bottom Left, Bottom Right
            printf "Balance board:   %5d %5d \n", $tl, $tr;
            printf "Sum:    %5d    %5d %5d \n", $tot, $bl, $br;
        } elsif($evt->{type} == $xwiimote::EVENT_BALANCE_BOARD_KEY) {
            ($code, $state) = $evt->get_key();
	    print "Balance board button state: " . $state . "\n";
	} else {
	    if($evt->{type} != $xwiimote::EVENT_ACCEL) {
		print "type:" . $evt->{type} . "\n";
	    }
	}
    };
    if($@) {
	if ($!{EAGAIN}) {
	    print "Try again\n";
	} else {
            print "Bad\n";
	}
    }

}

exit(0);
