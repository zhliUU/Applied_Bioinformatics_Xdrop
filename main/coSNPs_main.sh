#! /bin/bash
usage="$(basename "$0") [-h] -- Calls this help page.
$(basename "$0") 'Reads' 'Input positions' 'Referance genome' [-w] 'window Window_size' [-f] 'filter Filter_Threshold'  [-g] -- Runs the script with addtional graphical figure and a more detailed text based table.
$(basename "$0") 'Reads' 'Input positions' 'Referance genome' 'Window size' 'Filter threshold'
Example runs:
$(basename "$0") -h
$(basename "$0") ./Reads ./Input_positions ./Referance_genome -w 15 -f 0.95
$(basename "$0") ./Reads ./Input_positions ./Referance_genome -w 15 -f 0.95 -g
$(basename "$0") ./Reads ./Input_positions ./Referance_genome
$(basename "$0") ./Reads ./Input_positions ./Referance_genome -g

Where arguments are:
-Reads: It should contain the PacBio reads
-Input positions: abosulute positons from only one chromosome and the alternative neculotide
example;
chr17:738000 T
chr17:739000 G
'header of reference genome':'absolute position' 'alternative neclotide'
'Chromosomes names should have the same name as the reference genome'

Chromosome name needs to be the same or the script will be aborted.
The absolute position seperated by ':' should be larger than 0.
The alternative neculotide could be seperated by space or tab and should only be a neclotide capital A,T,C and G.

-Reference genome: This will be used to generate the referance and alternative sequences in the script.
Caution!:Header of reference reads should be the same as Input position!
-Window size: Is half of the window size. The total length of the referance and alternative query would be windowSize*2+1.
-Filter threshold: This value should be between 0 and 1, where 0 = 0% and 1 = 100%. It will remove reads that does not meet the threshold criteria.

Where arguments are location to files:
-Reads
-Input positons
-Referance genome

Where arguments are intergers or floats:
-Half window size (positive integer) needs to be greater or equal to 5.
The minium neclotide match is 8. A window size equal to 5 gives a total length of 11 (5*2+1).

-Filter threshold (float)
A value between 0.0 and 1.0. It removes bad data based on number of match incomparsion with total length from window size.
Example: '0.95', which means that 'number of match' should equal the length of total window size by 95%.

Where flags are:
    -h|--help  help function
    -g|--graphic  print better table using python:tabulate library, graphical output(future development)
    -w|--window [int] set the half window size of the sequences for realignment, default value is 50 bp
    -f|--filter [0-1] set the threshold of misaligned percentage for removing bad alignments, default value 0.8
    -o|--output prefix the output
    no flag: Run script with default window size 50bp:length 101bp and filter Threshold (0.8)

Output:
    -resultT1.txt It contains all the reads passing the threshold where 0 for reference, 1 for alternative, and * for unresolved neculotide.
    example: Lets asume we have 2 positons then each row should contain:
    'Reads'             'First position' 'nMatch for first position''Second position' 'nMatch for second positon'
    'PacBio read name'  '0, 1 or *'      'number of match'          '0, 1 or *'       'numer of match'

    You can compare 'number of match' to the total length of windowSize*2+1
    If window size is equal to 10 the total length is 21 and if 'number of match' is equal to 15,
    which means that 15 neclotides matched to the total of 21.

    resultT1.txt can also be opened in excel.

    -resultT2.txt It contains all possible combinations of 1 and 0 based on number of positions. Reads that contain unresolved postions are excluded.
    This will also include a counter for number of occurances.
    example: Lets asume we have 2 positons then each row should contain:
    Total reads 10
    'Counter' 'positon 1' 'postion 2'
    5          0            1
    3          1            0
    2          1            1"

POSITIONAL=()
checkG=0
Prefix=''
WindowSize='50'
FilterThrehold='0.8'
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo "$usage"
    exit
    ;;
    -o|--output)
    Prefix="$2"
    shift # past argument
    shift # past value
    ;;
    -g|--graphic)
    checkG=1
    shift # past argument
    ;;
    -w|--window)
    WindowSize="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--filter)
    FilterThrehold="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo 'Start!'
echo 'Current directory:'
pwd
PacBioINPUT=$1
input=$2
chrSeq=$3

if [ $# -eq 0 ]
then
 echo 'System abort: missing arguments in script'
 exit 1
fi
#########format prefix##
if [ ! -z $Prefix ]
then
  Prefix+='_'
fi
###################
errorHandler.py $FilterThrehold $WindowSize $input > tmp_errorMsg.txt
checkpoint=`tail -n 1 tmp_errorMsg.txt`
if [ $checkpoint = '0' ]
then
  echo 'Input parameters checkpoint passed!'
  rm tmp_errorMsg.txt
else
  cat tmp_errorMsg.txt
  rm tmp*
  exit 128
fi
#####################################################
rm -f Longread_Selected.bam
rm -f ${Prefix}result*
rm -f ${Prefix}bar_chart.png
cp $PacBioINPUT Longread_Selected.bam
rm -f query_Up${WindowSize}bp_Down${WindowSize}bp.fasta
numPos=0
echo "Selecting long reads from the .bam input mapped to the positions of interest..."
while IFS= read -r var
do
  numPos=$((numPos+1))
  numPosStr="$numPos"
  #echo $numPos
  pos=`echo $var | awk -F" " '{print $1}'`
  altNec=`echo $var | awk -F" " '{print $2}'`
  #Select PacBio input covering the current position
  SelectPacBio.sh $pos $WindowSize $numPosStr
  #Generate Alt Ref seq for alignment with WindowSize
  scriptWindowRef.py $pos $WindowSize $numPosStr
  bedtools getfasta -fi $chrSeq -bed tmpPosRef_$numPosStr.bed -fo tmpFasta.fasta
  generateAltseq.py $altNec tmpFasta.fasta $numPosStr $WindowSize
  rm tmpFasta.fasta
  rm tmpPosRef_*
  #remove empty lines
  awk 'NF' query_Up${WindowSize}bp_Down${WindowSize}bp.fasta > tmpSomething.fasta
  rm query_Up${WindowSize}bp_Down${WindowSize}bp.fasta
  cat tmpSomething.fasta > query_Up${WindowSize}bp_Down${WindowSize}bp.fasta
  rm tmpSomething.fasta

done < $input
#mv -f query_Up${WindowSize}bp_Down${WindowSize}bp.fasta ../Query/
echo "Start realignments!"
#send the alt/ref sequences for BLASR alignment
BLASRbash.sh query_Up${WindowSize}bp_Down${WindowSize}bp.fasta $WindowSize Longread_Selected.bam

#not working for /output/1-80_minMatch12_blasrResult_halfWin55.txt
#../output/text_minMatch12_1-40blasrResult_halfWin55.txt
echo "Filtering..."
#TODO: add threhold input
#rm -f ${Prefix}resultT*
BlasrOutput='BlasrResult_halfWin'${WindowSize}'.txt'
Filter_Blasr.py $BlasrOutput tmpOut1stFilter.txt
Filter_Blasr_Bad_data.py $numPos tmpOut1stFilter.txt tmpOut2ndFilter.txt $FilterThrehold
#handle the case where we have nMatch equal to Alt and Ref
#Result ouput should be: mutation boolean nMatch mutatio bolean pos 2 minMatch
# read 0 nMatch 1 nMatch
Filter_Blasr_3rd.py tmpOut2ndFilter.txt tmpOut3ndFilter.txt
results.py tmpOut3ndFilter.txt tmpOutresult.txt
filter_result.py $numPos tmpOutresult.txt ${Prefix}resultT1.txt
Sumfilter_result_improved.py ${Prefix}resultT1.txt ${Prefix}resultT1_label.txt
echo "Filtering finished."
#TODO: add printing command
#echo $BASH_COMMAND
echo "Number of long reads input:"
samtools view $PacBioINPUT | wc -l
echo "Number of selected long reads:"
#TODO: if selected PacBio file is empty/doesn't exist, terminate the software
samtools view Longread_Selected.bam | wc -l
#remove selected long reads
rm -f Longread_Selected.bam
echo "Number of reads containing all Pos and pass the numMatch threshold:"
wc -l ${Prefix}resultT1.txt
echo "Number of reads left for summarizing:"
wc -l < ${Prefix}resultT1_label.txt
echo "Summary:"
#summary final data:
#TODO: save into file AND graphical design for the data
cat ${Prefix}resultT1_label.txt | sort | uniq -c > tmpOut_resultT2.txt
#replacing empty lines/spaces? with /t
awk -v OFS="\t" '$1=$1' tmpOut_resultT2.txt > ${Prefix}resultT2.txt
rm ${Prefix}resultT1_label.txt
if [ $checkG -eq 0 ]
then
  cat ${Prefix}resultT2.txt
fi

if [ -z $Prefix ]
then
  Prefix2+='!@?'
else
  Prefix2=$Prefix
fi


if [ $checkG -eq 1 ]
then
  graph.py $input ${Prefix}resultT2.txt ${Prefix}resultT3.txt ${Prefix2}
fi
#add header for T2
echo 'Count	Position(s)' | cat - ${Prefix}resultT2.txt > temp && mv temp ${Prefix}resultT2.txt
rm tmpOut*
#remove the tmp file, use mv if needed to save
rm Header.sam
