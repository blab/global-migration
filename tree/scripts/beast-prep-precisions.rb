#!/usr/bin/ruby

filename = ARGV[0]
analysis = ARGV[1]

# strain name to array of attributes
samples = Hash.new
DATE = 0
PREC = 1
SEQ = 2

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

		precision = 0.0
		if date_precision == "month"
			precision = 0.082
		elsif date_precision == "year"
			precision = 1.0
		end

		entry = [date_decimal,precision,sequence]
		samples[name] = entry

	end

}
infile.close

print <<EOF
<?xml version="1.0" standalone="yes"?>
<beast>

	<taxon id="mostRecentDate">
		<date value="2013.0" direction="forwards" units="years"/>
	</taxon>

EOF

# taxa
puts "\t<taxa id=\"taxa\">"
samples.each_pair { |name, entry|
	print "\t\t<taxon id=\"#{name}\">\n"
	print "\t\t\t<date value=\"#{entry[DATE]}\" direction=\"forwards\" units=\"years\" precision=\"#{entry[PREC]}\"/>\n"
	print "\t\t</taxon>\n"
}
puts "\t</taxa>"

# sequences
print "\t<alignment id=\"alignment\" dataType=\"nucleotide\">\n"
samples.each_pair { |name, entry|
	entry[SEQ].gsub!(/N/) {|n| n = '?' }
	print "\t\t<sequence>\n"
	print "\t\t\t<taxon idref=\"#{name}\"/>\n"
	print "\t\t\t#{entry[SEQ]}\n"
	print "\t\t</sequence>\n"
}
print "\t</alignment>\n"

# patterns
print <<EOF
	<mergePatterns id="CP1+2.patterns">
		<patterns from="1" every="3" strip="false">
			<alignment idref="alignment"/>
		</patterns>
		<patterns from="2" every="3" strip="false">
			<alignment idref="alignment"/>
		</patterns>
	</mergePatterns>
	<patterns id="CP3.patterns" from="3" every="3" strip="false">
		<alignment idref="alignment"/>
	</patterns>
EOF

# starting tree
print <<EOF
	<constantSize id="constant" units="years">
		<populationSize>
			<parameter id="constant.popSize" value="5.0" lower="0.0"/>
		</populationSize>
	</constantSize>

	<coalescentTree id="startingTree">
		<taxa idref="taxa"/>
		<constantSize idref="constant"/>
	</coalescentTree>
EOF

# tree model
print <<EOF
	<treeModel id="treeModel">
		<coalescentTree idref="startingTree"/>
		<rootHeight>
			<parameter id="treeModel.rootHeight"/>
		</rootHeight>
		<nodeHeights internalNodes="true">
			<parameter id="treeModel.internalNodeHeights"/>
		</nodeHeights>
		<nodeHeights internalNodes="true" rootNode="true">
			<parameter id="treeModel.allInternalNodeHeights"/>
		</nodeHeights>
EOF

samples.each_pair { |name, entry|
if entry[PREC] > 0
print <<EOF
		<leafHeight taxon="#{name}">
			<parameter id="#{name}.height"/>
		</leafHeight>
EOF
end
}

print <<EOF
	</treeModel>
EOF

# coalescent likelihood
print <<EOF
	<coalescentLikelihood id="coalescent">
		<model>
			<constantSize idref="constant"/>
		</model>
		<populationTree>
			<treeModel idref="treeModel"/>
		</populationTree>
	</coalescentLikelihood>
EOF

# substitution model
print <<EOF
	<strictClockBranchRates id="branchRates">
		<rate>
			<parameter id="clock.rate" value="0.0050" lower="0.0"/>
		</rate>
	</strictClockBranchRates>

	<HKYModel id="CP1+2.hky">
		<frequencies>
			<frequencyModel dataType="nucleotide">
				<frequencies>
					<parameter id="CP1+2.frequencies" value="0.25 0.25 0.25 0.25"/>
				</frequencies>
			</frequencyModel>
		</frequencies>
		<kappa>
			<parameter id="CP1+2.kappa" value="2.0" lower="0.0"/>
		</kappa>
	</HKYModel>

	<HKYModel id="CP3.hky">
		<frequencies>
			<frequencyModel dataType="nucleotide">
				<frequencies>
					<parameter id="CP3.frequencies" value="0.25 0.25 0.25 0.25"/>
				</frequencies>
			</frequencyModel>
		</frequencies>
		<kappa>
			<parameter id="CP3.kappa" value="2.0" lower="0.0"/>
		</kappa>
	</HKYModel>

	<siteModel id="CP1+2.siteModel">
		<substitutionModel>
			<HKYModel idref="CP1+2.hky"/>
		</substitutionModel>
		<relativeRate>
			<parameter id="CP1+2.mu" value="1.0" lower="0.0"/>
		</relativeRate>
	</siteModel>

	<siteModel id="CP3.siteModel">
		<substitutionModel>
			<HKYModel idref="CP3.hky"/>
		</substitutionModel>
		<relativeRate>
			<parameter id="CP3.mu" value="1.0" lower="0.0"/>
		</relativeRate>
	</siteModel>

	<compoundParameter id="allMus">
		<parameter idref="CP1+2.mu"/>
		<parameter idref="CP3.mu"/>
	</compoundParameter>
EOF

# tree likelihood
print <<EOF
	<treeLikelihood id="CP1+2.treeLikelihood" useAmbiguities="false" stateTagName="CP1+2.states">
		<mergePatterns idref="CP1+2.patterns"/>
		<treeModel idref="treeModel"/>
		<siteModel idref="CP1+2.siteModel"/>
		<strictClockBranchRates idref="branchRates"/>
	</treeLikelihood>

	<treeLikelihood id="CP3.treeLikelihood" useAmbiguities="false" stateTagName="CP3.states">
		<patterns idref="CP3.patterns"/>
		<treeModel idref="treeModel"/>
		<siteModel idref="CP3.siteModel"/>
		<strictClockBranchRates idref="branchRates"/>
	</treeLikelihood>
EOF

# operators
print <<EOF
	<operators id="operators" optimizationSchedule="log">
EOF

precision_samples = 0
samples.each_pair { |name, entry|
if entry[PREC] > 0
	precision_samples += 1
end
}

date_operator_weight = 5.0 / precision_samples
samples.each_pair { |name, entry|
if entry[PREC] > 0
print <<EOF
		<uniformOperator weight="#{date_operator_weight}">
			<parameter idref="#{name}.height"/>
		</uniformOperator>
EOF
end
}

print <<EOF
		<scaleOperator scaleFactor="0.75" weight="0.1">
			<parameter idref="CP1+2.kappa"/>
		</scaleOperator>
		<scaleOperator scaleFactor="0.75" weight="0.1">
			<parameter idref="CP3.kappa"/>
		</scaleOperator>
		<deltaExchange delta="0.01" weight="0.1">
			<parameter idref="CP1+2.frequencies"/>
		</deltaExchange>
		<deltaExchange delta="0.01" weight="0.1">
			<parameter idref="CP3.frequencies"/>
		</deltaExchange>
		<deltaExchange delta="0.75" parameterWeights="1140 570" weight="2">
			<parameter idref="allMus"/>
		</deltaExchange>
		<scaleOperator scaleFactor="0.75" weight="3">
			<parameter idref="clock.rate"/>
		</scaleOperator>
		<subtreeSlide size="15.0" gaussian="true" weight="15">
			<treeModel idref="treeModel"/>
		</subtreeSlide>
		<narrowExchange weight="15">
			<treeModel idref="treeModel"/>
		</narrowExchange>
		<wideExchange weight="3">
			<treeModel idref="treeModel"/>
		</wideExchange>
		<wilsonBalding weight="3">
			<treeModel idref="treeModel"/>
		</wilsonBalding>
		<scaleOperator scaleFactor="0.75" weight="3">
			<parameter idref="treeModel.rootHeight"/>
		</scaleOperator>
		<uniformOperator weight="30">
			<parameter idref="treeModel.internalNodeHeights"/>
		</uniformOperator>
		<scaleOperator scaleFactor="0.75" weight="3">
			<parameter idref="constant.popSize"/>
		</scaleOperator>
		<upDownOperator scaleFactor="0.75" weight="3">
			<up>
				<parameter idref="clock.rate"/>
			</up>
			<down>
				<parameter idref="treeModel.allInternalNodeHeights"/>
			</down>
		</upDownOperator>
	</operators>
EOF

# MCMC
print <<EOF
	<mcmc id="mcmc" chainLength="1000000000" autoOptimize="true" operatorAnalysis="#{analysis}.ops">
		<posterior id="posterior">
			<prior id="prior">
				<logNormalPrior mean="1.0" stdev="1.25" offset="0.0" meanInRealSpace="false">
					<parameter idref="CP1+2.kappa"/>
				</logNormalPrior>
				<logNormalPrior mean="1.0" stdev="1.25" offset="0.0" meanInRealSpace="false">
					<parameter idref="CP3.kappa"/>
				</logNormalPrior>
				<uniformPrior lower="0.0" upper="1.0">
					<parameter idref="CP1+2.frequencies"/>
				</uniformPrior>
				<uniformPrior lower="0.0" upper="1.0">
					<parameter idref="CP3.frequencies"/>
				</uniformPrior>
				<ctmcScalePrior>
					<ctmcScale>
						<parameter idref="clock.rate"/>
					</ctmcScale>
					<treeModel idref="treeModel"/>
				</ctmcScalePrior>
				<exponentialPrior mean="1.0" offset="0.0">
					<parameter idref="constant.popSize"/>
				</exponentialPrior>
				<coalescentLikelihood idref="coalescent"/>
			</prior>
			<likelihood id="likelihood">
				<treeLikelihood idref="CP1+2.treeLikelihood"/>
				<treeLikelihood idref="CP3.treeLikelihood"/>
			</likelihood>
		</posterior>
		<operators idref="operators"/>

		<log id="screenLog" logEvery="100000">
			<column label="Posterior" dp="4" width="12">
				<posterior idref="posterior"/>
			</column>
			<column label="Prior" dp="4" width="12">
				<prior idref="prior"/>
			</column>
			<column label="Likelihood" dp="4" width="12">
				<likelihood idref="likelihood"/>
			</column>
			<column label="rootHeight" sf="6" width="12">
				<parameter idref="treeModel.rootHeight"/>
			</column>
			<column label="clock.rate" sf="6" width="12">
				<parameter idref="clock.rate"/>
			</column>
		</log>

		<log id="fileLog" logEvery="100000" fileName="#{analysis}.log" overwrite="false">
			<posterior idref="posterior"/>
			<prior idref="prior"/>
			<likelihood idref="likelihood"/>
			<parameter idref="treeModel.rootHeight"/>
			<parameter idref="constant.popSize"/>
			<parameter idref="CP1+2.kappa"/>
			<parameter idref="CP3.kappa"/>
			<parameter idref="CP1+2.frequencies"/>
			<parameter idref="CP3.frequencies"/>
			<compoundParameter idref="allMus"/>
			<parameter idref="clock.rate"/>
			<treeLikelihood idref="CP1+2.treeLikelihood"/>
			<treeLikelihood idref="CP3.treeLikelihood"/>
		</log>

		<log id="tipDateLog" logEvery="100000" fileName="#{analysis}.tipDates" overwrite="false">
EOF

samples.each_pair { |name, entry|
if entry[PREC] > 0
print <<EOF
			<parameter idref="#{name}.height"/>
EOF
end
}

print <<EOF
		</log>

		<logTree id="treeFileLog" logEvery="100000" nexusFormat="true" fileName="#{analysis}.trees" sortTranslationTable="true">
			<treeModel idref="treeModel"/>
			<posterior idref="posterior"/>
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