#! /bin/bash
#
# Automatically modify head of the fort.55 file.
#
# Usage: ./modify_head.sh fort.55 delete_array_file fort.56
#
# The new header gets created with modify_head.sh. For that, you need the
# fort.55 file and a file with the numver of virtual orbitals to delete in
# ahorizontal array (e.g. "14 9 9 4"). This script generates the file
# new_header_fort.55 which can be used to build the new fort.55
# Luckily, the formatting of the file is pretty forgiving and therefore the
# orbitals are created as a long vertical array
#
# Fur further processing, we save the integral part into the file
# "fort.55.integrals"
#
# (c) Paul Jerabek, 2017 (Massey University, Auckland, New Zealand)
#
# {{!Works only with the three-column style for the fort.55 file like the
# precompiled OMP version of Molpro 2015.1 uses it!}}
#

# Extract number of orbitals from the file
ORBITALS=`head -n 1 $1 | awk '{print $1}'`

# Calculate how many rows of orbitals we have in the 3-column layout
# We want to round up, so we're increasing the numerator by (denominator - 1)
# which works nicely in truncating arithmetic. Example: (N+15)/16
ROWS=$(( (ORBITALS + 2) / 3 ))

# Extract first line of fort.55 and save it to first_line_fort.55
head -n 1 $1 > first_line_fort.55

# Detach integral part of fort.55 and save it to file "fort.55.integrals"
tail -n +$(( ROWS + 3 )) $1 > fort.55.integrals

# Extract first line after the integral block of fort.55 and save it
# to after_int_fort.55
head -n $(( ROWS + 2 )) $1 | tail -n 1 > after_int_fort.55

# Our orbitals are betweens lines 2 and $ROWS. Save them in file
# temp_orig_header
head -n $(( ROWS + 1 )) $1 | tail -n +2 > temp_orig_header

# Find out, how many irreducible representations we have. There has to the
# number in the first column of the last line
TOTIRREP=`tail -n 1 temp_orig_header | awk '{print $1}'`
echo ""
echo "We have a total of $TOTIRREP irreducible representations."
echo ""

# Declare arrays
declare -a ORBARRAY
declare -a DELARRAY
declare -a DIFARRAY

# Grep for the total numbers of irred. rep.
i=1
while [ $i -le $TOTIRREP ]; do
    ORBARRAY[$i-1]=`grep -o $i temp_orig_header | wc -l`
    ((i++))
done

echo "Orbital array:"
echo ${ORBARRAY[*]}

tot=0
for i in ${ORBARRAY[@]}; do
    let tot+=$i
done
echo "Total: $tot"
echo ""

# Read in file with the number of orbitals per irred. rep. to delete and use
# the file temp_del.dat as a temporary place for the variables
i=1
while [ $i -le $TOTIRREP ]; do
    awk "{print \$$i}" $2 > temp_del.dat
    DELARRAY[$i-1]=`cat temp_del.dat`
    ((i++))
done

echo "Delete array:"
echo ${DELARRAY[*]}
tot=0
for i in ${DELARRAY[@]}; do
    let tot+=$i
done
echo "Total: $tot"
echo ""

# Subtract the delete array from the orbital array
i=1
while [ $i -le $TOTIRREP ]; do
    DIFARRAY[$i-1]=$(( ORBARRAY[i-1] - DELARRAY[i-1] ))
    ((i++))
done

echo "Resulting orbital array:"
echo ${DIFARRAY[*]}

tot=0
for i in ${DIFARRAY[@]}; do
    let tot+=$i
done
echo "Total: $tot"
echo ""

# Replace number of orbitals in first_line_fort.55 with the new number
NEWORBITALS=$tot
sed -i "s/$ORBITALS/$NEWORBITALS/" first_line_fort.55

# Build new fort.55 file
rm -f new_header_fort.55
cat first_line_fort.55 > new_header_fort.55

# Build strings out of 1, 2, 3, etc. for the irreducible representations and
# write to new_header_fort.55
#rm -f integral_head

k=1
for i in ${DIFARRAY[@]}; do
    j=1
    while [ $j -le $i ]; do
        echo $((k)) >> new_header_fort.55
        ((j++))
    done
    ((k++))
done

# Plug in the after-integrals line to the file new_header_fort.55
cat after_int_fort.55 >> new_header_fort.55

# Now, also modify the orbital vector in the last line of file fort.56
# First, we extract the vector and write it to a file "f56.orbital-vector.temp"
tail -n 1 $3 | sed -e 's/\s\+/\n/g' | tail -n +2 > f56.orbital-vector.temp

# We use SED to remove certain ranges from the bottom to the top. Benefit: We
# don't need to touch the electrons (2's) in the vector
# Example: sed f56.orbital-vector.temp -re '85,90d' | sed -re '72,80d' | sed
# -re '50,58d' | sed -re '23,36d'
#
# The bounds can be calculated as: Upper=Sum of orbital array; Lower=Sum of
# (orbital array - 1 element) + last element of Delarray + 1. Works fine,
# expect for the last irreducible representation. Here, the lower bound is just
# the one element from the resulting orbital array
#
#

echo ""
echo "Modify orbital vector from fort.56 file:"
i=$TOTIRREP
while [ $i -gt 0 ]; do

    LOWER=0
    for j in ${ORBARRAY[@]:0:$((i-1))}; do
        echo $j
        let LOWER+=$j
    done

    echo "+"

    echo ${DIFARRAY[i-1]}
    let LOWER+=${DIFARRAY[i-1]}+1

    UPPER=0
    for j in ${ORBARRAY[@]:0:$i}; do
        let UPPER+=$j
    done

#    if [ $i -eq 1 ]; then
#        let LOWER=${DIFARRAY[0]}+1
#    fi

    echo "Lower: $LOWER"
    echo "Upper: $UPPER"
    echo ""
    sed -i f56.orbital-vector.temp -re "$LOWER,$UPPER d"
    ((i--))
done

# Build new fort.56 file
sed '$d' $3 > fort.56.head

cat fort.56.head f56.orbital-vector.temp > fort.56.new

mv fort.56.new fort.56

# Clean up
rm -f first_line_fort.55 after_int_fort.55 temp_del.dat temp_orig_header integral_head fort.56.head f56.orbital-vector.temp



