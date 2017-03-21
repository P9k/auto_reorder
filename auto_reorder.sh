#! /bin/bash
#
# Automate the removal of the virtual orbitals in
# Molpro/MRCC calculation.
#
# Creates an AWK script which can act on the integral part of the fort.55 file
#
# We need to remove orbitals above a certain cutoff value (say, 30.0 au)
# from the integral file fort.55 and the vector in fort.56
#
# You can pre-input everything in a text file and then hand it over to the
# script like ./auto_reorder.sh < inputfile
#
#
# (c) Paul Jerabek, 2017 (Massey University, Auckland, New Zealand)
#
#      with creative help (design of the AWK script) by Lukas Pasteka
#

echo "How many irreducible representations?"
read TOTAL_IRREP

# Lower and upper orbital numbers for active orbitals
declare -a LORBARRAY
declare -a UORBARRAY

echo ""
echo ""

# Enter the number of lowest and the highest active orbital
i=1
while [ $i -le $TOTAL_IRREP ]; do
    LNUMBER=""
    UNUMBER=""
    echo ""
    echo "$i. Irreducible Representation. Number of lowest active orbital?"
    read LNUMBER
    echo ""
    echo "$i. Irreducible Representation. Number of highest active orbital?"
    read UNUMBER
    echo ""
    LORBARRAY[$i-1]=$LNUMBER
    UORBARRAY[$i-1]=$UNUMBER
    ((i++))
done

echo ""
echo ""

declare -a ORBNUMBERARRAY

i=1
while [ $i -le $TOTAL_IRREP ]; do
    ORBNUMBERARRAY[$i-1]="$(( UORBARRAY[i-1] - LORBARRAY[i-1] + 1 ))"
    ((i++))
done

#echo ""

#echo ${LORBARRAY[*]}
#echo ${UORBARRAY[*]}

#echo ""

#echo ${ORBNUMBERARRAY[*]}

#echo ""

# Total of all orbitals
TOTORBITAL=0
for i in ${ORBNUMBERARRAY[@]}; do
    let TOTORBITAL+=$i
done

echo "That's a total of $TOTORBITAL orbitals."

echo ""
echo ""

# Remove virtual orbitals from correlation

declare -a REMOVELORBARRAY
declare -a REMOVEUORBARRAY


# Enter the number of lowest and the highest virtual orbital you want to remove
i=1
while [ $i -le $TOTAL_IRREP ]; do
    LNUMBER=""
    echo ""
    echo "$i. Irreducible Representation. Remove everything after (including) orbital .. ?"
    read LNUMBER
    echo ""
    REMOVEORBARRAY[$i-1]=$LNUMBER
    ((i++))
done

# Difference array to compute how many orbital are going to be removed
declare -a DIFFORBARRAY

i=1
while [ $i -le $TOTAL_IRREP ]; do
    DIFFORBARRAY[$i-1]="$(( UORBARRAY[i-1] - REMOVEORBARRAY[i-1] + 1 ))"
    ((i++))
done


# Shift orbital numbers, so that they start with 1

# Declare new array for shifted orbital numbers
declare -a SHIFTLORBARRAY
declare -a SHIFTUORBARRAY

i=1
while [ $i -le $TOTAL_IRREP ]; do
    SHIFTLORBARRAY[$i-1]="$(( LORBARRAY[i-1] - LORBARRAY[i-1] + 1 ))"
    SHIFTUORBARRAY[$i-1]="$(( UORBARRAY[i-1] - LORBARRAY[i-1] + 1 ))"
    ((i++))
done

# Consecutive orbital numbers

declare -a CONSLORBARRAY
declare -a CONSUORBARRAY

# The first set stays the same
CONSLORBARRAY[0]="$(( SHIFTLORBARRAY[0] ))"
CONSUORBARRAY[0]="$(( SHIFTUORBARRAY[0] ))"

# For following orbitals, need the predecessing consecutive numbers
i=2
while [ $i -le $TOTAL_IRREP ]; do
    CONSLORBARRAY[$i-1]="$(( SHIFTLORBARRAY[i-1] + CONSUORBARRAY[i-2] ))"
    CONSUORBARRAY[$i-1]="$(( SHIFTUORBARRAY[i-1] + CONSUORBARRAY[i-2] ))"
    ((i++))
done

echo ""
echo "The consecutive numbers of the orbitals throughout the IRREPs are:"

echo ${CONSLORBARRAY[*]}
echo ${CONSUORBARRAY[*]}

echo ""

# Create AWK script!
rm -rf reorder.awk

echo "{"                   >> reorder.awk
echo "out=0;"              >> reorder.awk
echo "for (i=2;i<=5;i++){" >> reorder.awk


# Accumulating shift for the following orbitals. First shift is zero, next one
# is the gap between the blocks, then the sum of the first gap and the second
# gap... etc.
    echo "if (\$i >= $(( CONSLORBARRAY[0] - 1 )) && \$i <= $(( CONSUORBARRAY[0] - DIFFORBARRAY[0] ))) a[i-1]=\$i;" >> reorder.awk

SHIFT=0
i=2
while [ $i -le $TOTAL_IRREP ]; do
    SHIFT=$(( SHIFT + DIFFORBARRAY[i-2] ))
    echo "else if (\$i > $(( CONSLORBARRAY[i-1] - 1 )) && \$i <= $(( CONSUORBARRAY[i-1] - DIFFORBARRAY[i-1] ))) a[i-1]=\$i-$SHIFT;" >> reorder.awk
    ((i++))
done

# Continue with AWK script
echo "else out=1;}"        >> reorder.awk
echo "if (out==0) printf \"%20.16E%5i%5i%5i%5i\\n\",\$1,a[1],a[2],a[3],a[4]" >> reorder.awk
echo "}"                   >> reorder.awk


# Print what we got!

echo ""
echo "#########################"
echo "#This is our awk script:#"
echo "#########################"
echo""

cat reorder.awk

echo ""

