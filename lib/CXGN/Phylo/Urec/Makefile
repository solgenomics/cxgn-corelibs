

TARGET = urec
OBJ = rtree.o urtree.o
CFLAGS = -Wall -c 
CC = g++ 
LFLAGS =  -Wall

all: urec

rtree.o : rtree.h rtree.cpp
urtree.o : urtree.h urtree.cpp

%.o : %.cpp
	$(CC) $(CFLAGS) -o $@ $<

urec : $(OBJ) urec.o urtree.o
	$(CC) $(LFLAGS) -o $@ $(OBJ) $@.o

clean :
	rm -f *.o $(TARGET) *.old *~ x *.log

tgz : 
	tar czvf urec.tgz *.cpp *.h Makefile README
