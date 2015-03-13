#!/usr/bin/ruby

filename = ARGV[0]
start_step = ARGV[1].to_i
end_step = ARGV[2].to_i
sample_step = ARGV[3].to_i

infile = File.open(filename, "r")
infile.readlines.each { |line|

	step = nil
	
	match = line.match(/^(\d+)\t\S.+/)
	if match != nil
		step = match[1].to_i
	end
	
	match = line.match(/^tree STATE_(\d+) \[/)
	if match != nil
		step = match[1].to_i
	end	
	
	if step != nil
		if step >= start_step && step <= end_step && step % sample_step == 0
			puts line
		end
	else
		puts line
	end

}
infile.close
