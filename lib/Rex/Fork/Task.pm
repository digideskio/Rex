#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Fork::Task;

use strict;
use warnings;
use POSIX ":sys_wait_h";

# VERSION

BEGIN {

  use Rex::Shared::Var;
  share qw(@SUMMARY);

}

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  $self->{'running'} = 0;

  return $self;
}

sub start {
  my ($self) = @_;
  $self->{'running'} = 1;
  if ( $self->{pid} = fork ) { return $self->{pid}; }
  else {
    $self->{chld} = 1;
    my $func = $self->{task};

    my $success = eval { &$func($self) };
    $success    = 0 if $@;

    my $exit_code = $@ ? ($? || 1) : 0;

    push @SUMMARY, {
      task      => $self->{object}->name,
      server    => $self->{server},
      exit_code => $exit_code,
      success   => $success,
    };

    $self->{'running'} = 0;
    exit();
  }
}

sub wait {
  my ($self) = @_;
  my $rpid = waitpid( $self->{pid}, &WNOHANG );
  if ( $rpid == -1 ) { $self->{'running'} = 0; }

  return $rpid;
}

1;
