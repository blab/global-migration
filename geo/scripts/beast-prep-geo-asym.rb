#!/usr/bin/ruby

filename = ARGV[0]
treefile = ARGV[1]
analysis = ARGV[2]

# strain name to array of attributes
samples = Hash.new	
LOC = 0

# array of locations
locations = ["USACanada", "SouthAmerica", "Europe", "India", "NorthChina", "SouthChina", "JapanKorea", "SoutheastAsia", "Oceania", "China", "CentralAmerica", "Africa"]

locations_exists = Hash.new
locations.each {|location|
	locations_exists[location] = false
}

infile = File.open(filename, "r")
infile.readlines.each { |line|

	match = line.match(/^(\S+)\t(\d\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)/)
	if match != nil
	
		name = match[1]
		cal_date = match[2]
		date_decimal = match[3]	
		date_precision = match[4]
		region = match[5]
		country = match[6]
		general_location = match[7]
		specific_location = match[8]
		source = match[9]
		accession = match[10]
		sequence = match[11]
			
		entry = [region]
		samples[name] = entry
		
		locations_exists[region] = true
				
	end

}
infile.close

locations = locations.select {|location|
	locations_exists[location]
}

location_count = locations.length
geo_rate_count = (location_count * (location_count-1)).to_i

print <<EOF
<?xml version="1.0" standalone="yes"?>
<beast>	
EOF

# taxa
puts "\t<taxa id=\"taxa\">"
samples.each_pair { |name, entry|
	puts "\t\t<taxon id=\"#{name}\">"
	puts "\t\t\t<attr name=\"location\">#{entry[LOC]}</attr>"
	puts "\t\t</taxon>"	
}
puts "\t</taxa>"

# geo types
puts "\t<generalDataType id=\"geography\">"
locations.each { |loc|
	puts "\t\t<state code=\"#{loc}\"/>"
}
puts "\t</generalDataType>"

# geo patterns
print <<EOF
	<attributePatterns id="geoPatterns" attribute="location">
		<generalDataType idref="geography"/>
		<taxa idref="taxa"/>
	</attributePatterns>
EOF

# tree model
print <<EOF	
	<empiricalTreeDistributionModel id="treeModel" fileName="#{treefile}">
		<taxa idref="taxa"/>
	</empiricalTreeDistributionModel>	
	
	<statistic id="treeModel.currentTree" name="Current Tree">
		<empiricalTreeDistributionModel idref="treeModel"/>
	</statistic>	
EOF

# geo subs model
print <<EOF
	<generalSubstitutionModel id="originModel" name="origin">
		<generalDataType idref="geography"/>
		<frequencies>
			<frequencyModel id="geoFreqs" normalize="true">
				<generalDataType idref="geography"/>
				<frequencies>
					<parameter id="geoFreqs.frequencies" dimension="#{location_count}"/>
				</frequencies>
			</frequencyModel>
		</frequencies>
		<rates>
			<parameter id="geoRates" dimension="#{geo_rate_count}" value="1.0"/>
		</rates>
		<rateIndicator>
			<parameter id="geoIndicators" dimension="#{geo_rate_count}" value="1.0"/>
		</rateIndicator>
	</generalSubstitutionModel>
	
	<sumStatistic id="nonZeroRates" name="nonZeroRateCount" elementwise="true">
		<parameter idref="geoIndicators"/>
	</sumStatistic>
EOF

# geo site model
print <<EOF
	<siteModel id="geoSiteModel">
		<substitutionModel>
			<generalSubstitutionModel idref="originModel"/>
		</substitutionModel>
		<mutationRate>
			<parameter id="geoSiteModel.mu" value="0.1" lower="0.0" upper="10.0"/>
		</mutationRate>
	</siteModel>
EOF

# geo tree likelihood
print <<EOF
	<ancestralTreeLikelihood id="geoTreeLikelihood">
		<patterns idref="geoPatterns"/>
		<treeModel idref="treeModel"/>
		<siteModel idref="geoSiteModel"/>
		<generalSubstitutionModel idref="originModel"/>
	</ancestralTreeLikelihood>
EOF

# operators
print <<EOF
	<operators id="operators" optimizationSchedule="log">
		<empiricalTreeDistributionOperator weight="1">
			<empiricalTreeDistributionModel idref="treeModel"/>
		</empiricalTreeDistributionOperator>		
		<scaleOperator scaleFactor="0.75" weight="5">
			<parameter idref="geoSiteModel.mu"/>
		</scaleOperator>
		<scaleOperator scaleFactor="0.75" weight="15" scaleAllIndependently="true" autoOptimize="true">
			<parameter idref="geoRates"/>
		</scaleOperator>
		<bitFlipOperator weight="15">
			<parameter idref="geoIndicators"/>
		</bitFlipOperator>
		<bitFlipInSubstitutionModelOperator scaleFactor="0.75" weight="15" autoOptimize="true">
			<generalSubstitutionModel idref="originModel"/>
			<parameter idref="geoSiteModel.mu"/>
		</bitFlipInSubstitutionModelOperator>
	</operators>
EOF

# MCMC
print <<EOF
	<mcmc id="mcmc" chainLength="12000000" autoOptimize="true" operatorAnalysis="#{analysis}.ops">
		<posterior id="posterior">
			<prior id="prior">
				<cachedPrior>
					<gammaPrior shape="1.0" scale="1.0" offset="0.0">
						<parameter idref="geoRates"/>
					</gammaPrior>
					<parameter idref="geoRates"/>
				</cachedPrior>
				<exponentialPrior mean="1" offset="0">
					<parameter idref="geoSiteModel.mu"/>
				</exponentialPrior>
				<negativeBinomialPrior mean="#{location_count}" stdev="#{location_count}">
					<statistic idref="nonZeroRates"/>
				</negativeBinomialPrior>
				<generalSubstitutionModel idref="originModel"/>
			</prior>
			<likelihood id="likelihood">
				 <ancestralTreeLikelihood idref="geoTreeLikelihood"/>
			</likelihood>
		</posterior>
		<operators idref="operators"/>		
		
		<log id="screenLog" logEvery="10000">
			<column label="Posterior" dp="4" width="12">
				<posterior idref="posterior"/>
			</column>
			<column label="Prior" dp="4" width="12">
				<prior idref="prior"/>
			</column>
			<column label="Likelihood" dp="4" width="12">
				<likelihood idref="likelihood"/>
			</column>
			<column label="nonZeroRates" sf="6" width="12">
        		<sumStatistic idref="nonZeroRates"/>
        	</column>			
			<column label="clock.rate" sf="6" width="12">
				<parameter idref="geoSiteModel.mu"/>
			</column>
		</log>
		
		<log id="fileLog" logEvery="10000" fileName="#{analysis}.log" overwrite="false">
			<posterior idref="posterior"/>
			<prior idref="prior"/>
			<likelihood idref="likelihood"/>
			<parameter idref="geoSiteModel.mu"/>
			<sumStatistic idref="nonZeroRates"/>
			<parameter idref="geoRates"/>
			<parameter idref="geoIndicators"/>
		</log>		
			
		<logTree id="treeFileLog" logEvery="100000" nexusFormat="true" fileName="#{analysis}.trees" sortTranslationTable="true">
			<treeModel idref="treeModel"/>
			<posterior idref="posterior"/>
			<ancestralTreeLikelihood idref="geoTreeLikelihood"/>
		</logTree>
	</mcmc>		
EOF

# end
print <<EOF
	<report>
		<property name="timer">
			<mcmc idref="mcmc"/>
		</property>
	</report>
</beast>
EOF