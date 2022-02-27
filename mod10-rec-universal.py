#!/usr/bin/python

## usr/bin/env python3

import getopt
import sys

#from sys import argv
from time import time
from os import utime, stat

def check_digit(number):
  table = (0, 9, 4, 6, 8, 2, 7, 1, 3, 5)
  carry = 0
  for n in str(number):
      carry = table[(carry + int(n)) % 10]
  return (10 - carry) % 10

def main():
    try:
        # Define the getopt parameters
        opts, args = getopt.getopt(sys.argv[1:], 'i:o:x:hv', ['indigit', 'output', "help", "index="])
    except getopt.GetoptError as err:
        #if len(a) == 0 and len(opts) == 0 :
        print ('usage: mod10-rec.py -i <input_number> -x <path>')
        # Check if the options' length is 2 (can be enhanced)
        # print help information and exit:
        print(err)  # will print something like "option -a not recognized"
        #usage()
        sys.exit(2)
    output = None
    verbose = False
    indigit = ''
    names = [ ]
    sum = 0
    final = 0
    for o, a in opts:
        if o == "-v":
            verbose = True
        elif o in ("-i", "--input"):
            indigit = a
            final += check_digit(a)
        elif o in ("-o", "--output"):
            names = [ a ]
        elif o in ("-h", "--help"):
            print ('usage: mod10-rec.py -i <input_int> -o <output_filename> [-x <future_use> ] [-h]')
            #usage()
            sys.exit()
        elif o in ("-x", "--index"):
            output = a
        else:
            assert False, "unhandled option"
    #if len(opts) == 0 and len(opts) > 2:
    #  print ('usage: mod10-rec.py -i <input_number> -x <path>')
    #else:
      # Iterate the options and get the corresponding values
      #for opt, arg in opts:
      #   sum += int(arg)
      #print('Sum is {}'.format(sum))
    print(indigit+format(check_digit(indigit)));
    #print(format(check_digit(argv[1])));
    
    ##for opt, arg in opts:
    ##  final += check_digit(int(arg))
    final += check_digit(indigit)
    #print(argv[3]+format(final - check_digit(argv[1])));
    print(format(final - check_digit(indigit)));
    
    for element in names:
      fo = open(element, "wb")
      #wb/a
      #st_info = stat(name) # Storing file status
      # setting access time with file's access time (no change)
      # setting modified time with current time of the system)
      #utime(name, (st_info.st_atime, time()))
      fo.write(format(check_digit(indigit))+"\n")
      fo.close()

if __name__ == "__main__":
    main()

