#!/usr/bin/ruby

# This script is meant to be run on a .trees output file from BEAST. 
# By default BEAST converts tip names to consecutive integers.  
# This script converts back to the original tip names.

# First command line argument is file name
# Second command line argument is burn-in count

# Load array from file
filename = ARGV[0]
infile = File.new(filename, "r")
linearray = infile.readlines
infile.close
linearray.pop

# Setting up burnin
burnin = ARGV[1]
if burnin == nil then 
	burnin = 0 
else 
	burnin = Integer(burnin)
end

# Load hash with mapping from integer number to string name
h = Hash.new
check = false;
linearray.each { |line|
	
	if line =~ /Translate/ then
		check = true;
	end
	
	if check && line =~ /^\s+\d+ \S+/ then
		number, name = line.match(/(\d+) ([A-Za-z0-9\-\_\.\/\|]+)/)[1,2]
		h[number] = name
	#	print number,"\t",name,"\n"		
	end
	
	if check && line =~ /;/ then
		check = false;
	end

}

# Go through lines and print NEWICK lines with after replacing numbers for names
count = 0
linearray.each { |line|
	if line =~ /^tree/ then
		count += 1
		if count > burnin then
			line.gsub!(/\d+\[/) {|s| h[s.chop]+"[" }
			puts line
		end
	end
}