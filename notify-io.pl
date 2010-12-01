use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use Digest::MD5 qw(md5_hex);
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

$VERSION = '1.00';
%IRSSI = (
    authors     => 'Bill Casarin',
    contact     => 'jb55@freenode jb@jb55.com',
    name        => 'notify-io',
    description => 'Sends notifications to notify.io',
    license     => 'BSD',
);

Irssi::settings_add_str($IRSSI{'name'}, "notify_io_icon", "http://jb55.com/img/misc/irssi.png");
Irssi::settings_add_str($IRSSI{'name'}, "notify_io_api_key", "");
Irssi::settings_add_str($IRSSI{'name'}, "notify_io_email", "");
Irssi::settings_add_bool($IRSSI{'name'}, "notify_io_sticky", 1);

my $api_url = "http://api.notify.io/v1/notify/";
my $ua = LWP::UserAgent->new(agent => "$IRSSI{'name'}.pl/$VERSION", timeout => 10);

sub notify {
  my ($msg) = @_;

  my $api_key = Irssi::settings_get_str("notify_io_api_key");
  my $email = Irssi::settings_get_str("notify_io_email");
  my $is_sticky = Irssi::settings_get_bool("notify_io_sticky");
  my $icon = Irssi::settings_get_str("notify_io_icon");

  my $url = $api_url . md5_hex($email);

  my $req = POST $url, [
    text => $msg,
    title => "Irssi",
    icon => $icon,
    tags => $is_sticky ? "sticky" : "",
    api_key => $api_key,
  ];

  $ua->request($req)->as_string;
}

sub priv_msg_handler {
	my ($server, $msg, $nick, $address) = @_;
  notify("~" . $nick . ": " . $msg);
}

sub pub_msg_handler {
	my ($server, $msg, $nick, $address) = @_;
  if ($msg =~ /$server->{nick}/i) {
    notify($nick . ": " . $msg);
  }
}

Irssi::signal_add_last('message private', \&priv_msg_handler);
Irssi::signal_add_last('message public', \&pub_msg_handler);
