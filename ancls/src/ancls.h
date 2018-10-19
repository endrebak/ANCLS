
#include <stdint.h>


typedef struct {
  uint32_t start;
  uint32_t end;
  uint32_t index;
  int32_t sublist;
} Interval;


typedef struct {
  uint32_t start;
  uint32_t length;
} Header;
