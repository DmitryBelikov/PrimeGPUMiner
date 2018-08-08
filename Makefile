SRCS := $(wildcard hash/*.c)
SRCS += $(wildcard hash/*.cpp)
SRCS += $(wildcard *.c)
SRCS += $(wildcard *.cpp)

OBJS :=	miner.o \
				prime.o \
				bigmath.o \
				iniParser.o \
				util.o \
				hash/skein.o \
				hash/skein_block.o \
				hash/KeccakDuplex.o \
				hash/KeccakHash.o \
				hash/KeccakSponge.o \
				hash/Keccak-compact64.o

CUDA_SRCS := cuda/sieve.cu cuda/fermat.cu
CUDA_OBJS := cuda/sieve.o cuda/fermat.o

CUDA_PATH := /usr/local/cuda-9.1
NVCC := nvcc
CXX := g++
CC := gcc

LIB := -lpthread -lcrypto -lssl -lgmp -lprimesieve -lboost_system -lboost_thread

CUDA_LIB := -L$(CUDA_PATH)/lib64 -lcudadevrt -lcudart -lcuda
CUDA_INC += -I$(CUDA_PATH)/include

CFLAGS   := -std=c++0x
CXXFLAGS := -std=c++11 -msse2 -fopenmp -pthread -fno-strict-aliasing -fpermissive -g -O2
INCLUDES := #specify include path for host code

GPU_CARD := -arch=sm_35
NVCC_FLAGS += -std=c++11 -g -O2 -D_FORCE_INLINES -Xptxas "-v" --ptxas-options=-v
CUDA_LINK_FLAGS := -dlink

EXEC          := gpuminer
CUDA_LINK_OBJ := cuLink.o

all:	$(EXEC)
$(EXEC):	$(CUDA_OBJS)	$(OBJS)
					$(NVCC) $(GPU_CARD) $(CUDA_LINK_FLAGS) -o $(CUDA_LINK_OBJ) $(CUDA_OBJS)
					$(CXX) -o $@ $(OBJS) $(CUDA_OBJS) $(CUDA_LINK_OBJ) $(CUDA_LIB) $(LIB)

%.o:	%.c
	$(CC) -o $@ -c $(CFLAGS) $(INCLUDES) $<

%.o:	%.cpp
	$(CXX) -o $@ -c $(CXXFLAGS) $(INCLUDES) $<

cuda/sieve.o:	cuda/sieve.cu
	$(NVCC) $(GPU_CARD) $(NVCC_FLAGS) --maxrregcount=80 -o $@ -c $< $(CUDA_INC)

cuda/fermat.o:	cuda/fermat.cu
	$(NVCC) $(GPU_CARD) $(NVCC_FLAGS) --maxrregcount=128 -rdc=true -o $@ -c $< $(CUDA_INC)

clean:
	rm -f *.o
	rm -f $(EXEC)
	rm -f hash/*.o
	rm -f cuda/*.o

