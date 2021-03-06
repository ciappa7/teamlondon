#!/usr/bin/perl

#
#   CIS*2250 Project: Team London
#

#
#   PROBLEMS:
#       doesn't read lines containing 'é' (Québec, Montréal) 
#           >> lines 558691 to 766105
#       graphing
#
use strict;
use warnings;
use version;   our $VERSION = qv('5.16.0');
use Text::CSV  1.32; # for parsing

my $EMPTY = q{};
my $SPACE = q{ };
my $COMMA = q{,};

use Data::Dumper; # to print hashes/arrays easily 

my @data; # array stores entire file to read through
my $csv = Text::CSV->new({ sep_char => $COMMA }); # for parsing
my @crime_data; # array of hashes; each hash contains the (year/coordinate/value) of a line
                # hash only stored in array when coordinate is of the form x.2
my $line_count = 0;

# open file
# real file: crime_data.csv
# test file: test_data.csv
open my $data_fh, '<', 'crime_data.csv'
    or die "Unable to open names file: \n";

# store all contents of file in array 'data'
@data = <$data_fh>;

# PARSE DATA
# for each line in file...
foreach my $record ( @data ) {
    # skip the first line (header line)
    # 'next' command starts next iteration of for loop
    if ( $line_count ==  0 ) {
        $line_count++;
        next;
    }

    # parse each column of current line into $fields[n]
    # $fields[0] = year
    # $fields[5] = coordinate (FORMAT: location.violation.statistic)
    # $fields[6] = value (actual rate to be compared)
    if ( $csv->parse($record) ) {
        my @fields = $csv->fields();

        # regular expression searches through each coordinate
        # if coordinate is of the format 'x.2', store it in hash 'data'
        #   >> \. matches the character . literally and 2  matches the character 2 literally
        #   >> $  asserts position at the end of the string
        # push hash containing (year/coordinate/value) into array crime_data
        if ($fields[5] =~ /\.2$/) {
            my %data = (
                year => $fields[0],
                coordinate => $fields[5],
                value => $fields[6]
            );

            # create a REFERENCE to the hash data (memory location), so we can push it onto the array
            # reference is: \%data
            # to get values we will dereference: ${$data[0]}{year}
            push @crime_data, \%data;
        }
    } else {
        warn "Line/record could not be parsed: $line_count.\n";
    }
    
    # check if reading file correctly: print every 10000th line if read correctly
    if ($line_count % 10000 == 0) {
        print "ON LINE: $line_count\n";
    }

    $line_count++;
}

close $data_fh;

# store geo code of all provinces (from crime_data) in provinces hash
my %provinces = (
    newfoundland => 2,
    pei => 4,
    nova_scotia => 5,
    new_brunswick => 7,
    quebec => 9,
    ontario => 16,
    manitoba => 28,
    saskatchewan => 30,
    alberta => 33,
    british_columbia => 36,
    yukon => 40,
    northwest_territories => 41,
    nunavut => 42
);

# store geo code of all cities (from crime_data) in cities hash
my %cities = (
    st_johns => 3,
    halifax => 6,
    moncton => 43,
    saint_john => 8,
    saguenay => 10,
    quebec => 11,
    sherbrooke => 12,
    trois_rivieres => 13,
    montreal => 14,
    ottawa_gatineau_quebec => 15,
    ottawa_gatineau_both => 17,
    ottawa_gatineau_ontario => 18,
    kingston => 27,
    peterborough => 44,
    toronto => 19,
    hamilton => 20,
    st_catharines_niagara => 21,
    kitchener_cambridge_waterloo => 22,
    brantford => 45,
    guelph => 46,
    london => 23,
    windsor => 24,
    barrie => 47,
    sudbury => 25,
    thunder_bay => 26,
    winnipeg => 29,
    regina => 31,
    saskatoon => 32,
    calgary => 34,
    edmonton => 35,
    kelowna => 48,
    abbotsford_mission => 39,
    vancouver => 37,
    victoria => 38
);

# function aggregates required data (from user input)
# finds highest / lowest value
sub aggregate_data {
    # From user input: year, violation #, 0 (city) or 1 (province), 0 (low) or 1 (high)
    my ( $year, $violation, $is_province, $is_highest ) = @_;

    # Build an array of possible crime_data values using:
    # ('provinces' or 'cities' hash value) + (the violation number) + '.2'
    my @coordinate_keys;
    my $current_value;
    my $current_location;

    # if entered 1 for province, go through provinces hash
    # create array of desired coordinates using province.violation.2 
    if ($is_province) {
        for my $key (values %provinces) {
            push @coordinate_keys, "$key.$violation.2";
        }

    # if entered 0 for city, go through cities hash
    # create array of desired coordinates using city.violation.2 
    } else {
        for my $key (values %cities) {
            push @coordinate_keys, "$key.$violation.2";
        }
    }

    # go through crime_data array (has crime hashes containing year, coordinate, value)
    foreach my $crime_record ( @crime_data ) {

        my %record = %{$crime_record};

        # if year in current hash = year given by user
        if ($record{year} eq $year) {
            # sort thorugh coordinates we created using (province/city).violation.2
            foreach my $coordinate_key ( @coordinate_keys ) {
                # if coordinate in current hash = coordinate we created 
                if ($record{crime_data} eq $coordinate_key) {
                    # print Dumper(\%record);

                    # SORT VALUES!!! if not first loop..
                    if ($current_value) {
                        # if user wants highest value, and value in hash is greater than current highest value
                        # set current_value to the record value
                        if ($is_highest == 1 and $record{value} > $current_value) {
                            $current_value = $record{value}; 
                            $current_location = $coordinate_key;      
                        }
                        # if user wants lower value, and value in hash is lesser than current lowest value
                        # set current_value to the record value
                        if ($is_highest == 0 and $record{value} < $current_value) {
                            $current_value = $record{value};  
                            $current_location = $coordinate_key;      
                        }
                    # if first loop: set value in hash equal to current_value
                    } else {
                        $current_value = $record{value};       
                    }
                }
            }
        }
    }
    # if no value is found (current_value never defined), print error
    unless (defined $current_value) {
        $current_value = "Value not found.\n";
    }

    # return highest/lowest value
    return $current_value;
}

# USER INTERFACE
print "Hello. Welcome to our program xD. Ask us a question!\n";
print "What (province/city) had the (highest/lowest) rate of (violation) in (year)?\n";

# GET INPUT (chomp newlines xD)
print "Province or city? (1 for province, 0 for city): ";
my $is_province = <STDIN>;
chomp $is_province;

print "Highest or Lowest (1 for highest, 0 for lowest): ";
my $is_highest = <STDIN>;
chomp $is_highest;

print "         \n\n~~~~~~~~~~~~~~~~~~~ VIOLATION NUMBERS ~~~~~~~~~~~~~~~~~~~\n\n";
print "     Abduction under the age 14, not parent or guardian     39\n";
print "     Arson                                                  84\n";
print "     Dangerous vehicle operation, causing death            161\n";
print "     Luring a child                                         21\n";
print "     Participate in activity of terrorist group            128\n";
print "     Total breaking and entering                            65\n";
print "     Total Criminal Code traffic violations                148\n";
print "     Total Impaired Driving                                149\n";
print "     Total robbery                                          34\n";
print "     Total violent Criminal Code violations                  4\n";
print "     Shoplifting \$5,000 or under                            79\n";
print "     Total sexual violations against children               17\n\n";

print "Violation number: ";
my $violation_number = <STDIN>;
chomp $violation_number;

print "Year (1998-2015): ";
my $year = <STDIN>;
chomp $year;

my $result = aggregate_data($year, $violation_number, $is_province, $is_highest);

# RETURN OUTPUT
print "~~~~~~~~~~~~~~~~~~~ RESULT ~~~~~~~~~~~~~~~~~~~\n";
if($is_highest) {
    print("The highest rate in $year is $result.\n");
} else {
    print("The lowest rate in $year is $result.\n");
}
print "~~~~~~~~~~~~~~~~~~~ LATER  ~~~~~~~~~~~~~~~~~~~\n";

# # Lowest value in city
#print aggregate_data("2003", "2", 0, 0), "\n";
# # Lowest value in province
# print aggregate_data("2003", "2", 1, 0), "\n";
# # Highest value in city
# aggregate_data("2003", "2", 0, 1);
# # Highest value in province
# aggregate_data("2003", "2", 1, 1);

# while(<>)
