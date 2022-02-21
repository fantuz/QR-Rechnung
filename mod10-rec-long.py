#!/usr/bin/python

## usr/bin/env python3

import getopt
import sys

#from sys import argv
from time import time
from os import utime, stat

# Get the arguments from the command-line except the filename
argv = sys.argv[1:]
sum = 0
final = 0
names = ['/home/max/Downloads/PDF-facture/crc-ref.csv']

try:
    # Define the getopt parameters
    opts, args = getopt.getopt(argv, 'i:x:', ['foperand', 'soperand'])
    # Check if the options' length is 2 (can be enhanced)
    if len(opts) == 0 and len(opts) > 2:
      print ('usage: mod10-rec.py -i <input_number> -x <test_decode>')
    #else:
      # Iterate the options and get the corresponding values
      #for opt, arg in opts:
      #   sum += int(arg)
      #print('Sum is {}'.format(sum))

except getopt.GetoptError:
    # Print something useful
    print ('usage: mod10-rec.py -i <input_number> -b <test>')
    sys.exit(2)

def check_digit(number):
  table = (0, 9, 4, 6, 8, 2, 7, 1, 3, 5)
  carry = 0
  for n in str(number):
      carry = table[(carry + int(n)) % 10]
  return (10 - carry) % 10

print(argv[1]+format(check_digit(argv[1])));
#print(format(check_digit(argv[1])));

for opt, arg in opts:
  final += check_digit(int(arg))
#print(argv[3]+format(final - check_digit(argv[1])));

#for name in argv[1:]:
#  open(name, 'a')
for name in names:
  fo = open(name, "wb")
  #wb/a
  #st_info = stat(name) # Storing file status
  # setting access time with file's access time (no change)
  # setting modified time with current time of the system)
  #utime(name, (st_info.st_atime, time()))
  fo.write(format(check_digit(argv[1]))+"\n")
  fo.close()

