#!/usr/bin/ruby

require 'descriptive_statistics'
			
stems = [	
		"h3_small", "h1_small", "vic_small", "yam_small", 
		"h3_small_r2", "h1_small_r2", "vic_small_r2", "yam_small_r2",
		"h3_large", "h1_large", "vic_large", "yam_large"
		]

puts "type | Fst "
puts "---- | --- "		

stems.each {|stem|

	index_to_name = Hash.new
	name_to_values = Hash.new

	infile = File.open("#{stem}_geo/out_fst.skylines", "r")
	vFst = Array.new
	infile.readlines.each { |line|	
		match = line.match(/^fst\t\S+\t\S+\t(\S+)\t\S+/)
		if match != nil
			value = match[1].to_f
			vFst.push(value)
		end
	}
	infile.close
	
	puts "#{stem} | #{vFst.mean.round(2)}"
				
}

