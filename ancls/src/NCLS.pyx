
cimport cython
from cancls cimport Interval, Header

from libcpp.vector cimport vector
from libcpp.algorithm cimport sort as stdsort


from libcpp cimport bool
from libc.stdint cimport uint32_t, int32_t
from numpy import uint32


cdef bool starts_then_longest(const Interval lhs, const Interval rhs):

  if lhs.start < rhs.start:
      return True
  elif lhs.start > rhs.start:
      return False
  elif lhs.end < rhs.end:
      return False
  else:
      return True



cdef bool sublists_then_start(const Interval lhs, const Interval rhs):

  if lhs.sublist < rhs.sublist:
      return True
  elif lhs.sublist > rhs.sublist:
      return False
  elif lhs.start < rhs.start:
      return False
  else:
      return True


cdef class NCLS:

    cdef vector[Interval] intervals
    cdef uint32_t nsub

    @cython.boundscheck(False)
    @cython.wraparound(False)
    @cython.initializedcheck(False)
    def __cinit__(self, const uint32_t [::1] starts, const uint32_t [::1] ends, const uint32_t [::1] ids):

        cdef:
            uint32_t i
            uint32_t ntop # number intervals in main list
            uint32_t nsub # number intervals not in main list
            uint32_t nlists # number sublists that together contain all intervals in nsub
            length = len(starts)
            Interval interval
            vector[Interval] intervals = vector[Interval](len(starts))
            vector[Interval] sublists #= vector[Interval]

        for i in range(length):
            interval.start = starts[i]
            interval.end = ends[i]
            interval.index = ids[i]
            intervals[i] = interval

        self.intervals = intervals
        print("first sort")
        self.sort_on_starts_then_longest()
        print("add parents")
        self.nsub = self.add_parents_inplace()

        if self.nsub > 0:

            self.set_header_indexes(intervals)
            self.sort_on_sublists_then_starts()

            self.create_sublist_header()

            self.remove_sublists()



    def sort_on_starts_then_longest(self):
        stdsort(self.intervals.begin(), self.intervals.end(), starts_then_longest)


    def sort_on_sublists_then_starts(self):
        cdef:
            vector[Interval] sublists = self.sublists

        stdsort(sublists.begin(), sublists.end(), sublists_then_start)


    def add_parents_inplace(self):
        cdef:
            uint32_t nsub
            int32_t parent
            uint32_t i = 0
            uint32_t length = self.intervals.size()
            vector[Interval] intervals = self.intervals
            bool same_or_not_contained

        nsub = 0

        while (i < length):
            parent = i
            i = parent + 1

            while i < length and parent >= 0: # TOP LEVEL LIST SCAN
                same_or_not_contained = (intervals[i].end > intervals[parent].end) \
                    or (intervals[i].end == intervals[parent].end and intervals[i].start == intervals[parent].start)

                print("same_or_not_contained", same_or_not_contained)
                if same_or_not_contained:
                    parent = intervals[parent].sublist # all are -1 on instantiation
                else:
                    intervals[i].sublist = parent # MARK AS CONTAINED IN parent
                    nsub += 1 # COUNT TOTAL #SUBLIST ENTRIES
                    parent = i # AND PUSH ONTO RECURSIVE STACK
                    i += 1 # ADVANCE TO NEXT INTERVAL

        return nsub


    def set_header_indexes(self):

        cdef:
            uint32_t nsub = self.nsub
            uint32_t i = 0
            uint32_t j = 0
            uint32_t nlists = 0
            uint32_t parent
            vector[Interval] sublists = vector[Interval](self.nsub)
            vector[Interval] intervals = self.intervals

        for i in range(self.intervals.size()):
            parent = self.intervals[i].sublist
            if parent >= 0:
                sublists[j].start = i
                sublists[j].sublist = parent
                j += 1

                if intervals[parent].sublist == -1:
                    intervals[parent].sublist = nlists
                    nlists += 1

            intervals[i].sublist = -1

        self.nlists = nlists
        self.sublists = sublists


    def create_sublist_header(self):

        cdef:
            vector[Header] subheaders = vector[Header]()
            vector[Interval] sublists = self.sublists
            vector[Interval] intervals = self.intervals

        subheaders.resize(self.nlists)

        for i in range(self.nsub):

            j = sublists[i].start
            parent = sublists[i].sublist

            sublists[i] = intervals[j]

            k = intervals[parent].sublist

            if subheaders[k].length == 0:
                subheaders[k].start = i

            subheaders[k].length += 1

            intervals[j].sublist = -2 # mark for deletion


        self.sublists = sublists


    def remove_sublists(self):

        # print("intervals 1", intervals)
        cdef:
            uint32_t i, j, k
            vector[Header] subheaders = vector[Header]()
            vector[Interval] sublists = self.sublists
            vector[Interval] intervals = self.intervals
            uint32_t nlists = self.nlists
            uint32_t nsub = self.nsub

        i, j = 0, 0
        for i in range(len(intervals)):
            if intervals[i].sublist != -2:
                if j < i:
                    intervals[j] = intervals[i]
                    j += 1

        k = 0
        for k in range(0, nsub):
            intervals[j + k] = sublists[k]

        for i in range(nlists):

            subheaders[i].start += j

        self.ntop = j
