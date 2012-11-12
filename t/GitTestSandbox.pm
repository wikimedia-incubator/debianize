package GitTestSandbox;
use strict  ;
use warnings;
use Carp;


sub new {
  my ($class_name,$prefix) = @_;

  $prefix ||= "test-repo-";

  my $timestamp      = `date +"%s"`; 
  chomp $timestamp;

  my $mock_repo_path = $prefix . $timestamp;
  my $mock_file_path = "A.txt";

  my $obj = {
    mock_repo_path => $mock_repo_path,
    mock_file_path => $mock_file_path,
  };

  return bless $obj,$class_name;
};

#
# Generate new commit in test repo after modifying the file in it a bit
# (make sure we have enough randomness so the file is completely different
# from the one before)
#

sub gen_repo_new_commit {
  my ($self,$message) = @_;
  my $mock_file_path = $self->{mock_file_path};
  my $mock_repo_path = $self->{mock_repo_path};

  my $random1 = int(rand(99999999));
  my $random2 = int(rand(99999999));
  my $date    = `date +%N`;
  chomp $date;
  `
  cd $mock_repo_path;
  echo "$date-$random1-$random2" > $mock_file_path;
  git commit -am "$message";
  `;
};

#
# Generate new tag in test repo
#
sub gen_repo_new_tag {
  my ($self,$name) = @_;
  my $mock_repo_path = $self->{mock_repo_path};
  `
  cd $mock_repo_path;
  git tag -a "$name" -m "New tag $name"
  `;
};

#
# Create a mock repo to test the git2deblogs script on
#
sub gen_repo {
  my ($self) = @_;

  my $mock_repo_path = $self->{mock_repo_path};
  my $mock_file_path = $self->{mock_file_path};

  `
  mkdir -p $mock_repo_path;
  mkdir $mock_repo_path/debian;
  cd    $mock_repo_path;
  git init;
  echo "TestData" > $mock_file_path;
  git add $mock_file_path;
  git commit -am "1 commit";
  `;
};

sub destroy_repo {
  my ($self) = @_;
  croak "Error: not safe to delete" if 
    $self->{mock_repo_path} eq "./"      ||
    $self->{mock_repo_path} eq "./debian";
  `rm -rf $self->{mock_repo_path}`;
};

sub run_git2deblogs {
  my ($self) = @_;
  my $mock_repo_path = $self->{mock_repo_path};

  `
  cd $mock_repo_path
  ln -s ../git2deblogs.pl git2deblogs
  ./git2deblogs --generate
  `;
};

1;
