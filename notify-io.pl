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

Irssi::settings_add_str($IRSSI{'name'}, "notify_io_api_url", "http://api.notify.io/v1/notify/");
Irssi::settings_add_str($IRSSI{'name'}, "notify_io_icon", "http://jb55.com/img/misc/irssi.png");
Irssi::settings_add_str($IRSSI{'name'}, "notify_io_api_key", "");
Irssi::settings_add_str($IRSSI{'name'}, "notify_io_email", "");
Irssi::settings_add_bool($IRSSI{'name'}, "notify_io_sticky", 1);

my $ua = LWP::UserAgent->new(agent => "$IRSSI{'name'}.pl/$VERSION", timeout => 10);

sub notify {
  my ($msg) = @_;

  my $api_key = Irssi::settings_get_str("notify_io_api_key");
  my $email = Irssi::settings_get_str("notify_io_email");
  my $is_sticky = Irssi::settings_get_bool("notify_io_sticky");
  my $icon = Irssi::settings_get_str("notify_io_icon");
  my $api_url = Irssi::settings_get_str("notify_io_api_url");

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

sub highlight_handler {
  my ($dest, $text, $stripped) = @_;
  my $nick = Irssi::parse_special('$;');

  if ($dest->{level} & (MSGLEVEL_HILIGHT | MSGLEVEL_MSGS) && ($dest->{level} & MSGLEVEL_NOHILIGHT) == 0) {
    if ($dest->{level} & MSGLEVEL_PUBLIC) {
      notify($dest->{target} . " ~" . $nick . ": " . $stripped);
    }
  }
}


Irssi::signal_add_last('message private', \&priv_msg_handler);
Irssi::signal_add_last('print text', \&highlight_handler);
