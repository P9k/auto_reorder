#! /bin/bash
#
# Toolkit for the deletion of virtual orbitals from Molpro/MRCC calculations:
#
# (1) The new header gets created with modify_head.sh. For that, you need the
# fort.55 file and a file with the numver of virtual orbitals to delete in a
# horizontal array (e.g. "14 9 9 4"). This generates the file
# "new_header_fort.55"
#
# (2) The script auto_reorder.sh generates an AWK script which eliminates the
# chosen virtual orbitals from the integral list in the lower part of fort.55
# and reorders the numbers. It creates the file "reorder.awk"
#
# (3) Execute the AWK script and put the newly ordered integrals below the file
# "new_header_fort.55" to create the new "fort.55" file
#
#
# Usage: ./automate-fort.55-conversion.sh fort.55 delete_orbital_array
# inputfile_for_auto_reorder.sh

./modify_head.sh $1 $2

./auto_reorder.sh < $3

awk -f reorder.awk fort.55.integrals >> new_header_fort.55

mv new_header_fort.55 fort.55

rm -f fort.55.integrals
