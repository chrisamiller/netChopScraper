perl netchopSubmit.pl tests/input.fa >tests/newoutput

if [[ ! -s tests/newoutput ]];then
    echo "ERROR: retrieving results failed"
fi
if [[ $(diff tests/newoutput tests/output.scraped | wc -l) -gt 0 ]];then
    echo "ERROR: output 'tests/newoutput' does not match expected 'tests/output.scraped'"
    exit
fi

perl parseNetChop.pl tests/newoutput >tests/newparsed

if [[ ! -s tests/newparsed ]];then
    echo "ERROR: parsing results failed"
fi
if [[ $(diff tests/newparsed tests/output.parsed | wc -l) -gt 0 ]];then
    echo "ERROR: output 'tests/newparsed' does not match expected 'tests/output.parsed'"
    exit
fi


rm -f tests/newoutput tests/newparsed
echo "All tests passed!"
