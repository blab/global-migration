#!/usr/bin/ruby

require 'descriptive_statistics'
			
stems =	[
		"h3_small", "h3_small_r2", "h3_large",
		"h1_small", "h1_small_r2", "h1_large",
		"vic_small", "vic_small_r2", "vic_large",
		"yam_small", "yam_small_r2", "yam_large"
		]

puts "type | pop size | diversity | TMRCA | time to trunk | pos 1&2 rate | pos 3 rate | rate ratio"
puts "---- | -------- | --------- | ----- | ------------- | ------------ | ---------- | ----------"		

stems.each {|stem|

	index_to_name = Hash.new
	name_to_values = Hash.new

	infile = File.open("#{stem}_tree/#{stem}_sample.log", "r")
	infile.readlines.each { |line|

		match = line.match(/^state\t\S.+/)
		if match != nil
			line.split("\t").each_with_index {|name, index|
				index_to_name[index] = name
			}
		end
	
		match = line.match(/^\d+\t\S.+/)
		if match != nil
			line.split("\t").each_with_index {|value, index|
				name = index_to_name[index]
				if name_to_values[name] == nil
					name_to_values[name] = Array.new
				end
				name_to_values[name].push(value.to_f)
			}
		end

	}
	infile.close

	vPopSize = name_to_values["constant.popSize"] 
	vCP12Rate = name_to_values["clock.rate"].zip(name_to_values["CP1+2.mu"]).map{|i,j| i*j }
	vCP3Rate = name_to_values["clock.rate"].zip(name_to_values["CP3.mu"]).map{|i,j| i*j }
	vRatio = name_to_values["CP1+2.mu"].zip(name_to_values["CP3.mu"]).map{|i,j| i/j }		

	infile = File.open("#{stem}_tree/out.skylines", "r")
	vDiv = Array.new
	vTMRCA = Array.new
	infile.readlines.each { |line|	
		match = line.match(/^div\t\S+\t\S+\t(\S+)\t\S+/)
		if match != nil
			value = match[1].to_f
			vDiv.push(value)
		end
		match = line.match(/^tmrca\t\S+\t\S+\t(\S+)\t\S+/)
		if match != nil
			value = match[1].to_f
			vTMRCA.push(value)
		end		
	}
	infile.close
	
	infile = File.open("#{stem}_tree/out.tips", "r")
	vTimeToTrunk = Array.new
	infile.readlines.each { |line|	
		match = line.match(/^time_to_trunk\t\S+\t\S+\t(\S+)\t\S+\t(\S+)/)
		if match != nil
			date = match[1].to_f
			value = match[2].to_f
			if date < 2010
				vTimeToTrunk.push(value.to_f)
			end
		end
	}
	infile.close	

	puts "#{stem} | #{vPopSize.mean.round(1)} | #{vDiv.mean.round(2)} | #{vTMRCA.mean.round(2)} | #{vTimeToTrunk.mean.round(2)} | #{vCP12Rate.mean.round(4)} | #{vCP3Rate.mean.round(4)} | #{vRatio.mean.round(2)}"
				
}

