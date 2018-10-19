from libc.stdint cimport uint32_t, uint16_t
from libcpp cimport bool


cdef extern from "ancls.h":

    ctypedef struct Interval:
        uint32_t start
        uint32_t end
        uint32_t index
        uint32_t sublist

    ctypedef struct Header:
        uint32_t start
        uint32_t length

    # bool starts_then_longest(Interval lhs, Interval rhs)
