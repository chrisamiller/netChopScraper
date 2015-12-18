use WWW::Mechanize;

#get the webpage with the form
my $mech = WWW::Mechanize->new();
$mech->show_progress(1);
my $url = "http://www.cbs.dtu.dk/services/NetChop/";

$mech->get($url);

validateInput($ARGV[0]);

#fill the fields with the appropriate data and submit
my $fields = {
    'SEQSUB' => $ARGV[0],
#'SEQPASTE' => "ASTPGHTIIYEAVCLHNDRTTIP",  #can't use newlines at the moment - guess I'll have to upload a file instead?
};
$result = $mech->submit_form(
        form_number => 2,
        fields => $fields,
    );
my $content = $result->content();


#NetChop sends off a batch job and puts up an auto-refreshing intermediate page.
#grab that page and parse out the URL that the results will ultimately appear at
my $resulturl;
if($content =~ /reload automatically. Otherwise <a href="([^\"]+)">/){
    $resulturl = $1;
} else {
    print STDERR "ERROR: Can't find the result URL - page retrieved was:";
    print $content . "\n";
    die("no result URL found");
}


#try to get the results page
my $timeout_seconds = 300;
my $mech2 = WWW::Mechanize->new();
$mech2->show_progress(1);

sleep 5;
$mech2->get($resulturl);
# print STDERR $mech2->content . "\n";

# if the results page still isn't ready, keep trying every 10 seconds until it is either ready
# or the timeout value is reached

my $wait_time = 0;
while($mech2->content() =~ /<title>Job status/ && $wait_time < $timeout_seconds){
    print STDERR ("Waiting for results from URL: $resulturl \n");
    sleep 10;
    $wait_time = $wait_time + 10;
    $mech2->get($resulturl);
}


#now we have some kind of results. If it failed on the NetChop side, print an error
if($mech2->content() =~ /Failed run/){
    die("ERROR: NetChop Server returned a \"Failed run\" status.");
}

#if it succeeded, then print the results
if($mech2->content() =~ /prediction results/){
    parseResults($mech2->content);
} else {
    #did we timeout? If so, let the user know where they can ultimately find their data:
    die("ERROR - did not recieve results after waiting for $wait_time seconds\nResults were expected to be at $resulturl\n");
}


sub parseResults{
    my $content = shift;
    my @lines = split("\n",$content);
    my $indata = 0;
    foreach my $line (@lines){
        if($line =~ /pre>/){
            $indata = !$indata;
            next;
        }
        print $line . "\n" if $indata;
    }
    return;
}


sub validateInput{
    #for now, just checks to see if there are less than 100 sequences in the fasta
    my $file = shift;
    my $seqcount = 0;

    my $inFh = IO::File->new( $file ) || die "can't open file\n";
    while( my $line = $inFh->getline )
    {
        if($line =~ /^>/){
            $count++;
        }
    }
    if($count > 100){
        die("ERROR - the NetChop server will not accept more than 100 sequences - split your file into smaller chunks and try again")
    }
    close($inFh);
    return 1;
}
